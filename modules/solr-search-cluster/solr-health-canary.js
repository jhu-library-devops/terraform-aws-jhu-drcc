const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const https = require('https');
const http = require('http');

const solrHealthCheck = async function () {
    const collections = ['search', 'oai', 'statistics'];
    const solrUrl = process.env.solrUrl || 'http://solr.dspace-prod.local:8983/solr';
    
    log.info(`Using Solr URL: ${solrUrl}`);
    
    for (const collection of collections) {
        await synthetics.executeStep(`check_${collection}_health`, async () => {
            const url = `${solrUrl}/admin/collections?action=CLUSTERSTATUS&collection=${collection}`;
            log.info(`Checking health for collection: ${collection} at ${url}`);
            
            const parsedUrl = new URL(url);
            const httpModule = parsedUrl.protocol === 'https:' ? https : http;
            
            const response = await new Promise((resolve, reject) => {
                const req = httpModule.get(url, { timeout: 10000 }, (res) => {
                    let data = '';
                    res.on('data', chunk => data += chunk);
                    res.on('end', () => {
                        if (res.statusCode >= 200 && res.statusCode < 300) {
                            resolve({ statusCode: res.statusCode, body: data });
                        } else {
                            reject(new Error(`HTTP ${res.statusCode}: ${res.statusMessage}`));
                        }
                    });
                });
                req.on('error', reject);
                req.on('timeout', () => {
                    req.destroy();
                    reject(new Error('Request timeout'));
                });
            });
            
            const responseBody = JSON.parse(response.body);
            const health = responseBody?.cluster?.collections?.[collection]?.health || 'UNKNOWN';
            
            log.info(`Collection ${collection} health: ${health}`);
            
            if (health === 'RED') {
                throw new Error(`Collection ${collection} is in RED state!`);
            }
            if (health === 'UNKNOWN') {
                throw new Error(`Collection ${collection} health is UNKNOWN!`);
            }
        });
    }
    
    log.info('All Solr collections health check completed successfully');
};

exports.handler = async () => {
    return await synthetics.executeStep('solr_health_check', solrHealthCheck);
};
