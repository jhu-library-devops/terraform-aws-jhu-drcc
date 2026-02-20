import json
import logging
import time
from urllib.parse import urlencode

logger = logging.getLogger()

def wait_for_solr_ready(http, solr_url, node_name):
    """Wait for Solr node to join cluster"""
    for i in range(30):
        try:
            cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
            response = http.request('GET', cluster_url)
            cluster_status = json.loads(response.data.decode('utf-8'))
            if node_name in cluster_status['cluster']['live_nodes']:
                return True
        except Exception as e:
            logger.info(f"Solr not ready yet: {e}")
        logger.info(f"Waiting for Solr node {node_name}... attempt {i+1}/30")
        time.sleep(10)
    return False

def move_replicas(http, solr_url, old_node, new_node):
    """Move replicas from old to new node with leader-aware handling"""
    cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
    response = http.request('GET', cluster_url)
    cluster_status = json.loads(response.data.decode('utf-8'))
    
    moved_replicas = []
    collections = cluster_status['cluster']['collections']
    
    leaders_on_old_node = []
    followers_on_old_node = []
    
    for collection_name, collection_data in collections.items():
        for shard_name, shard_data in collection_data['shards'].items():
            for replica_name, replica_data in shard_data['replicas'].items():
                if replica_data['node_name'] == old_node:
                    if replica_data.get('leader') == 'true':
                        leaders_on_old_node.append((collection_name, shard_name, replica_name, replica_data))
                    else:
                        followers_on_old_node.append((collection_name, shard_name, replica_name, replica_data))
    
    logger.info(f"Old node {old_node} has {len(leaders_on_old_node)} leaders and {len(followers_on_old_node)} followers")
    
    for collection_name, shard_name, replica_name, replica_data in followers_on_old_node:
        logger.info(f"Moving follower replica {collection_name}/{shard_name}/{replica_name}")
        if move_single_replica(http, solr_url, collection_name, shard_name, replica_name, new_node):
            moved_replicas.append(f"{collection_name}/{shard_name}/{replica_name}")
        time.sleep(2)
    
    for collection_name, shard_name, replica_name, replica_data in leaders_on_old_node:
        logger.info(f"Moving LEADER replica {collection_name}/{shard_name}/{replica_name}")
        if move_single_replica(http, solr_url, collection_name, shard_name, replica_name, new_node):
            moved_replicas.append(f"{collection_name}/{shard_name}/{replica_name}")
        time.sleep(5)
    
    return moved_replicas

def wait_for_async_request(http, solr_url, request_id, timeout=300):
    """Poll REQUESTSTATUS until operation completes"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            status_url = f"{solr_url}/solr/admin/collections?action=REQUESTSTATUS&requestid={request_id}&wt=json"
            response = http.request('GET', status_url)
            result = json.loads(response.data.decode('utf-8'))
            
            state = result.get('status', {}).get('state')
            if state == 'completed':
                logger.info(f"Request {request_id} completed successfully")
                return True
            elif state == 'failed':
                logger.error(f"Request {request_id} failed: {result}")
                return False
            
            logger.info(f"Request {request_id} state: {state}, waiting...")
            time.sleep(5)
        except Exception as e:
            logger.warning(f"Error checking request status: {e}")
            time.sleep(5)
    
    logger.error(f"Request {request_id} timed out after {timeout}s")
    return False

def move_single_replica(http, solr_url, collection_name, shard_name, replica_name, target_node):
    """Move a single replica and wait for completion"""
    import uuid
    request_id = str(uuid.uuid4())
    
    params = {
        'action': 'MOVEREPLICA',
        'collection': collection_name,
        'shard': shard_name,
        'replica': replica_name,
        'targetNode': target_node,
        'async': request_id,
        'wt': 'json'
    }
    
    move_url = f"{solr_url}/solr/admin/collections?{urlencode(params)}"
    move_response = http.request('GET', move_url)
    move_result = json.loads(move_response.data.decode('utf-8'))
    
    if move_result.get('responseHeader', {}).get('status') == 0:
        logger.info(f"Move request submitted for {collection_name}/{shard_name}/{replica_name}, request_id: {request_id}")
        # Wait for async operation to complete
        if wait_for_async_request(http, solr_url, request_id):
            logger.info(f"Successfully moved {collection_name}/{shard_name}/{replica_name}")
            return True
        else:
            logger.error(f"Failed to complete move for {collection_name}/{shard_name}/{replica_name}")
            return False
    else:
        logger.error(f"Failed to submit move request for {collection_name}/{shard_name}/{replica_name}: {move_result}")
        return False

def check_remaining_replicas(http, solr_url, old_node):
    """Check if any replicas remain on old node"""
    try:
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_status = json.loads(response.data.decode('utf-8'))
        
        remaining = []
        collections = cluster_status['cluster']['collections']
        
        for collection_name, collection_data in collections.items():
            for shard_name, shard_data in collection_data['shards'].items():
                for replica_name, replica_data in shard_data['replicas'].items():
                    if replica_data['node_name'] == old_node:
                        remaining.append(f"{collection_name}/{shard_name}/{replica_name}")
        
        return remaining
    except Exception as e:
        logger.error(f"Failed to check remaining replicas: {e}")
        return ["unknown"]

def find_down_nodes_with_replicas(cluster_status):
    """Find nodes that are down but still have replicas assigned"""
    live_nodes = set(cluster_status['cluster']['live_nodes'])
    down_nodes_with_replicas = set()
    
    for collection_name, collection_data in cluster_status['cluster']['collections'].items():
        for shard_name, shard_data in collection_data['shards'].items():
            for replica_name, replica_data in shard_data['replicas'].items():
                node_name = replica_data['node_name']
                if node_name not in live_nodes:
                    down_nodes_with_replicas.add(node_name)
    
    return list(down_nodes_with_replicas)

def move_replicas_from_down_node(http, solr_url, down_node, live_nodes):
    """Move all replicas from a down node to live nodes"""
    import uuid
    logger.info(f"Moving replicas from down node: {down_node}")
    
    # Get current cluster status
    cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
    response = http.request('GET', cluster_url)
    cluster_status = json.loads(response.data.decode('utf-8'))
    
    moved_replicas = []
    
    for collection_name, collection_data in cluster_status['cluster']['collections'].items():
        for shard_name, shard_data in collection_data['shards'].items():
            for replica_name, replica_data in shard_data['replicas'].items():
                if replica_data['node_name'] == down_node:
                    # Select target node (round-robin)
                    target_node = live_nodes[len(moved_replicas) % len(live_nodes)]
                    
                    try:
                        # Delete the down replica first (async)
                        request_id = str(uuid.uuid4())
                        delete_url = f"{solr_url}/solr/admin/collections?action=DELETEREPLICA&collection={collection_name}&shard={shard_name}&replica={replica_name}&async={request_id}&wt=json"
                        http.request('GET', delete_url)
                        wait_for_async_request(http, solr_url, request_id, timeout=60)
                        logger.info(f"Deleted down replica {replica_name} from {collection_name}")
                        
                        # Add new replica on live node (async)
                        request_id = str(uuid.uuid4())
                        add_url = f"{solr_url}/solr/admin/collections?action=ADDREPLICA&collection={collection_name}&shard={shard_name}&node={target_node}&type={replica_data['type']}&async={request_id}&wt=json"
                        http.request('GET', add_url)
                        wait_for_async_request(http, solr_url, request_id, timeout=300)
                        logger.info(f"Added replica for {collection_name}/{shard_name} on {target_node}")
                        
                        moved_replicas.append({
                            'collection': collection_name,
                            'shard': shard_name,
                            'from_node': down_node,
                            'to_node': target_node,
                            'type': replica_data['type']
                        })
                        
                    except Exception as e:
                        logger.error(f"Failed to move replica {replica_name}: {e}")
    
    return moved_replicas

def rebalance_replicas(http, solr_url, target_node):
    """Rebalance replicas to match pattern: 1 NRT leader + 2 PULL followers (1 per node)"""
    import uuid
    try:
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_status = json.loads(response.data.decode('utf-8'))
        
        live_nodes = list(cluster_status['cluster']['live_nodes'])
        collections = cluster_status['cluster']['collections']
        rebalanced = []
        deleted = []
        
        for collection_name, collection_data in collections.items():
            for shard_name, shard_data in collection_data['shards'].items():
                replicas = shard_data['replicas']
                
                # Count replicas by type and node
                nrt_replicas = [(name, data) for name, data in replicas.items() if data['type'] == 'NRT']
                pull_replicas = [(name, data) for name, data in replicas.items() if data['type'] == 'PULL']
                
                # Delete excess PULL replicas (keep only 2), but only if on dead nodes or in failed state
                if len(pull_replicas) > 2:
                    logger.warning(f"{collection_name}/{shard_name} has {len(pull_replicas)} PULL replicas, checking for excess to delete")
                    for replica_name, replica_data in pull_replicas[2:]:
                        node_name = replica_data.get('node_name')
                        state = replica_data.get('state')
                        
                        # Only delete if on dead node or in recovery_failed state
                        if node_name not in live_nodes or state == 'recovery_failed':
                            request_id = str(uuid.uuid4())
                            delete_url = f"{solr_url}/solr/admin/collections?action=DELETEREPLICA&collection={collection_name}&shard={shard_name}&replica={replica_name}&async={request_id}&wt=json"
                            delete_response = http.request('GET', delete_url)
                            delete_result = json.loads(delete_response.data.decode('utf-8'))
                            if delete_result.get('responseHeader', {}).get('status') == 0:
                                if wait_for_async_request(http, solr_url, request_id, timeout=60):
                                    logger.info(f"Deleted excess PULL replica {replica_name} (node: {node_name}, state: {state})")
                                    deleted.append(f"{collection_name}/{shard_name}/{replica_name}")
                        else:
                            logger.info(f"Skipping deletion of {replica_name} - on live node {node_name} with state {state}")
                
                # Ensure PULL replicas are distributed (1 per node)
                pull_by_node = {}
                for replica_name, replica_data in pull_replicas[:2]:  # Only consider first 2
                    node = replica_data['node_name']
                    if node not in pull_by_node:
                        pull_by_node[node] = []
                    pull_by_node[node].append((replica_name, replica_data))
                
                # Move PULL replicas if multiple on same node
                for node, node_replicas in pull_by_node.items():
                    if len(node_replicas) > 1:
                        # Keep first, move others
                        for replica_name, replica_data in node_replicas[1:]:
                            # Find a node without a PULL replica for this shard
                            target = next((n for n in live_nodes if n not in pull_by_node), live_nodes[0])
                            request_id = str(uuid.uuid4())
                            move_url = f"{solr_url}/solr/admin/collections?action=MOVEREPLICA&collection={collection_name}&shard={shard_name}&replica={replica_name}&targetNode={target}&async={request_id}&wt=json"
                            move_response = http.request('GET', move_url)
                            move_result = json.loads(move_response.data.decode('utf-8'))
                            if move_result.get('responseHeader', {}).get('status') == 0:
                                if wait_for_async_request(http, solr_url, request_id):
                                    logger.info(f"Moved PULL replica {replica_name} to {target}")
                                    rebalanced.append(f"{collection_name}/{shard_name}/{replica_name}")
        
        if deleted:
            logger.info(f"Deleted {len(deleted)} excess replicas")
        if rebalanced:
            logger.info(f"Rebalanced {len(rebalanced)} replicas")
        
        # Reload collections that had operations
        collections_modified = set()
        for item in deleted + rebalanced:
            coll_name = item.split('/')[0]
            collections_modified.add(coll_name)
        
        for coll_name in collections_modified:
            try:
                reload_url = f"{solr_url}/solr/admin/collections?action=RELOAD&name={coll_name}&wt=json"
                http.request('GET', reload_url, timeout=30.0)
                logger.info(f"Reloaded collection {coll_name}")
                
                # Wait briefly for collection to stabilize
                wait_for_collection_healthy(http, solr_url, coll_name, timeout=10)
            except Exception as e:
                logger.warning(f"Failed to reload {coll_name}: {e}")
        
        return rebalanced + deleted
        
    except Exception as e:
        logger.error(f"Replica rebalancing failed: {e}")
        return []

def update_nodeset_constraints(http, solr_url, new_node):
    """Check and update NodeSet constraints for collections"""
    try:
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_status = json.loads(response.data.decode('utf-8'))
        
        collections = cluster_status['cluster']['collections']
        updated_collections = []
        
        for collection_name in collections.keys():
            props_url = f"{solr_url}/solr/admin/collections?action=COLLECTIONPROP&collection={collection_name}&wt=json"
            props_response = http.request('GET', props_url)
            props_result = json.loads(props_response.data.decode('utf-8'))
            
            if 'properties' in props_result:
                props = props_result['properties']
                has_nodeset = any(key.startswith('createNodeSet') or key.startswith('rule') for key in props.keys())
                
                if has_nodeset:
                    logger.info(f"Updating NodeSet constraints for collection {collection_name}")
                    modify_url = f"{solr_url}/solr/admin/collections?action=MODIFYCOLLECTION&collection={collection_name}&rule=node:*&wt=json"
                    modify_response = http.request('GET', modify_url)
                    modify_result = json.loads(modify_response.data.decode('utf-8'))
                    
                    if modify_result.get('responseHeader', {}).get('status') == 0:
                        updated_collections.append(collection_name)
                        logger.info(f"Updated NodeSet for {collection_name}")
                    else:
                        logger.warning(f"Failed to update NodeSet for {collection_name}: {modify_result}")
        
        return updated_collections
        
    except Exception as e:
        logger.warning(f"NodeSet constraint check failed: {e}")
        return []

def check_collection_health(http, solr_url):
    """Check if all collections are healthy (GREEN status)"""
    try:
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_status = json.loads(response.data.decode('utf-8'))
        
        unhealthy_collections = []
        collections = cluster_status['cluster']['collections']
        
        for collection_name, collection_data in collections.items():
            health = collection_data.get('health', 'UNKNOWN')
            if health != 'GREEN':
                unhealthy_collections.append(f"{collection_name}:{health}")
        
        return unhealthy_collections
        
    except Exception as e:
        logger.error(f"Failed to check collection health: {e}")
        return [f"health_check_failed:{str(e)}"]

def tombstone_dead_nodes(http, solr_url):
    """Remove all replicas from dead (non-live) nodes"""
    import uuid
    try:
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_status = json.loads(response.data.decode('utf-8'))
        
        live_nodes = set(cluster_status['cluster']['live_nodes'])
        collections = cluster_status['cluster']['collections']
        deleted = []
        
        logger.info(f"Live nodes: {live_nodes}")
        
        # Process collections sequentially
        for collection_name, collection_data in collections.items():
            logger.info(f"Tombstoning collection: {collection_name}")
            collection_had_deletions = False
            
            for shard_name, shard_data in collection_data['shards'].items():
                # Count active replicas on live nodes by type
                active_nrt = sum(1 for r in shard_data['replicas'].values() 
                                if r.get('type') == 'NRT' and r.get('state') == 'active' and r.get('node_name') in live_nodes)
                active_pull = sum(1 for r in shard_data['replicas'].values() 
                                 if r.get('type') == 'PULL' and r.get('state') == 'active' and r.get('node_name') in live_nodes)
                
                for replica_name, replica_data in shard_data['replicas'].items():
                    node_name = replica_data.get('node_name')
                    
                    if node_name not in live_nodes:
                        replica_type = replica_data.get('type', 'NRT')
                        data_dir = replica_data.get('dataDir')
                        
                        # Check if deletion would leave shard without minimum replicas
                        if replica_type == 'NRT' and active_nrt < 1:
                            logger.warning(f"Skipping deletion of {replica_name} - would leave shard without NRT replica")
                            continue
                        
                        logger.warning(f"Found replica on dead node: {collection_name}/{shard_name}/{replica_name} on {node_name}")
                        logger.info(f"DataDir preserved on EFS: {data_dir}")
                        
                        try:
                            request_id = str(uuid.uuid4())
                            delete_url = f"{solr_url}/solr/admin/collections?action=DELETEREPLICA&collection={collection_name}&shard={shard_name}&replica={replica_name}&async={request_id}&wt=json"
                            delete_response = http.request('GET', delete_url)
                            delete_result = json.loads(delete_response.data.decode('utf-8'))
                            
                            if delete_result.get('responseHeader', {}).get('status') == 0:
                                if wait_for_async_request(http, solr_url, request_id, timeout=60):
                                    logger.info(f"Deleted replica {replica_name} from dead node {node_name}")
                                    deleted.append(f"{collection_name}/{shard_name}/{replica_name}@{node_name}")
                                    collection_had_deletions = True
                        except Exception as e:
                            logger.error(f"Failed to delete {replica_name} from {node_name}: {e}")
            
            # Reload collection after deletions
            if collection_had_deletions:
                try:
                    reload_url = f"{solr_url}/solr/admin/collections?action=RELOAD&name={collection_name}&wt=json"
                    http.request('GET', reload_url, timeout=30.0)
                    logger.info(f"Reloaded collection {collection_name}")
                    
                    # Wait briefly for collection to stabilize
                    wait_for_collection_healthy(http, solr_url, collection_name, timeout=10)
                except Exception as e:
                    logger.warning(f"Failed to reload {collection_name}: {e}")
        
        logger.info(f"Tombstone complete: deleted {len(deleted)} replicas from dead nodes")
        return deleted
        
    except Exception as e:
        logger.error(f"Tombstone operation failed: {e}")
        return []

def check_existing_data(http, solr_url, collection, shard):
    """Check all replicas for collection/shard across cluster to find directory with most documents"""
    try:
        # Query cluster status to find all replicas (including on dead nodes)
        cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
        response = http.request('GET', cluster_url)
        cluster_data = json.loads(response.data.decode('utf-8'))
        
        # Find all replicas for this collection/shard and pick the one with most documents
        best_match = None
        max_docs = 0
        
        collections = cluster_data['cluster']['collections']
        if collection in collections:
            shards = collections[collection].get('shards', {})
            if shard in shards:
                replicas = shards[shard].get('replicas', {})
                
                for replica_name, replica_data in replicas.items():
                    # Check if replica has dataDir and get document count from leader
                    data_dir = replica_data.get('dataDir')
                    instance_dir = replica_data.get('instanceDir')
                    
                    # Try to get index info from replica's core
                    core_name = replica_data.get('core')
                    if core_name and data_dir:
                        try:
                            core_url = f"{solr_url}/solr/admin/cores?action=STATUS&core={core_name}&wt=json"
                            core_response = http.request('GET', core_url, timeout=5.0)
                            core_data = json.loads(core_response.data.decode('utf-8'))
                            num_docs = core_data.get('status', {}).get(core_name, {}).get('index', {}).get('numDocs', 0)
                            
                            if num_docs > max_docs:
                                max_docs = num_docs
                                best_match = {
                                    'dataDir': data_dir,
                                    'numDocs': num_docs,
                                    'instanceDir': instance_dir,
                                    'replica': replica_name
                                }
                        except:
                            # Core may not be accessible, but dataDir still exists on EFS
                            if data_dir and not best_match:
                                best_match = {
                                    'dataDir': data_dir,
                                    'numDocs': 0,
                                    'instanceDir': instance_dir,
                                    'replica': replica_name
                                }
        
        if best_match and max_docs > 0:
            logger.info(f"Found existing data from {best_match['replica']} with {max_docs} documents at {best_match['dataDir']}")
            return best_match
        elif best_match:
            logger.info(f"Found dataDir from {best_match['replica']} at {best_match['dataDir']} (document count unavailable)")
            return best_match
        
        return None
    except Exception as e:
        logger.warning(f"Failed to check existing data: {e}")
        return None

def wait_for_collection_healthy(http, solr_url, collection, timeout=60):
    """Poll until collection health is GREEN"""
    cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
    
    for i in range(timeout // 5):
        try:
            response = http.request('GET', cluster_url)
            data = json.loads(response.data.decode('utf-8'))
            health = data['cluster']['collections'].get(collection, {}).get('health', 'UNKNOWN')
            
            if health == 'GREEN':
                logger.info(f"Collection {collection} is healthy")
                return True
            logger.debug(f"Collection {collection} health: {health}, waiting...")
            time.sleep(5)
        except Exception as e:
            logger.warning(f"Health check failed: {e}")
            time.sleep(5)
    
    logger.warning(f"Collection {collection} did not reach GREEN health within {timeout}s")
    return False

def handle_recovery_failed_replicas(http, solr_url, max_passes=2):
    """Delete replicas in recovery_failed state and recreate them only if needed"""
    import uuid
    
    all_deleted = []
    all_recreated = []
    all_recovered = []
    
    for pass_num in range(max_passes):
        logger.info(f"Recovery pass {pass_num + 1}/{max_passes}")
        
        try:
            cluster_url = f"{solr_url}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
            response = http.request('GET', cluster_url)
            cluster_status = json.loads(response.data.decode('utf-8'))
            
            collections = cluster_status['cluster']['collections']
            live_nodes = list(cluster_status['cluster']['live_nodes'])
            pass_deleted = []
            pass_recreated = []
            pass_recovered = []
            
            # Process collections sequentially (mimic Solr restart behavior)
            for collection_name, collection_data in collections.items():
                logger.info(f"Processing collection: {collection_name}")
                collection_had_operations = False
                
                # Process NRT replicas first (priority), then PULL replicas
                for replica_priority in ['NRT', 'PULL']:
                    for shard_name, shard_data in collection_data['shards'].items():
                        # Count active replicas by type
                        active_nrt = sum(1 for r in shard_data['replicas'].values() 
                                        if r.get('type') == 'NRT' and r.get('state') == 'active')
                        active_pull = sum(1 for r in shard_data['replicas'].values() 
                                         if r.get('type') == 'PULL' and r.get('state') == 'active')
                        
                        for replica_name, replica_data in shard_data['replicas'].items():
                            if replica_data.get('state') != 'recovery_failed':
                                continue
                            
                            replica_type = replica_data.get('type', 'NRT')
                            
                            # Skip if not matching current priority pass
                            if replica_type != replica_priority:
                                continue
                            
                            logger.warning(f"Found recovery_failed replica: {collection_name}/{shard_name}/{replica_name}")
                            collection_had_operations = True
                            failed_node = replica_data.get('node_name')
                            core_name = replica_data.get('core')
                            data_dir = replica_data.get('dataDir')
                            instance_dir = replica_data.get('instanceDir')
                            
                            # First, attempt to recover the replica using Core API
                            try:
                                logger.info(f"Attempting REQUESTRECOVERY for {collection_name}/{shard_name}/{replica_name}")
                                if core_name:
                                    recovery_url = f"{solr_url}/solr/admin/cores?action=REQUESTRECOVERY&core={core_name}&wt=json"
                                    recovery_response = http.request('GET', recovery_url, timeout=10.0)
                                    recovery_result = json.loads(recovery_response.data.decode('utf-8'))
                                    
                                    if recovery_result.get('responseHeader', {}).get('status') == 0:
                                        logger.info(f"REQUESTRECOVERY initiated for {replica_name}, polling for recovery...")
                                        
                                        # Poll for recovery completion (up to 60 seconds)
                                        recovered = False
                                        for i in range(12):
                                            time.sleep(5)
                                            poll_response = http.request('GET', cluster_url)
                                            poll_data = json.loads(poll_response.data.decode('utf-8'))
                                            current_state = poll_data['cluster']['collections'][collection_name]['shards'][shard_name]['replicas'].get(replica_name, {}).get('state')
                                            
                                            if current_state == 'active':
                                                logger.info(f"Replica {replica_name} recovered successfully")
                                                pass_recovered.append(f"{collection_name}/{shard_name}/{replica_name}")
                                                recovered = True
                                                break
                                        
                                        if recovered:
                                            continue
                                        else:
                                            logger.warning(f"Recovery timeout for {replica_name}, state still: {current_state}")
                            except Exception as e:
                                logger.warning(f"REQUESTRECOVERY failed for {replica_name}: {e}")
                            
                            # Only delete replicas on dead nodes (mimic Solr restart behavior)
                            if failed_node not in live_nodes:
                                logger.info(f"Node {failed_node} is dead, proceeding with deletion")
                            else:
                                logger.info(f"Skipping deletion - node {failed_node} is live, recovery should complete naturally")
                                continue
                            
                            # Delete the failed replica
                            request_id = str(uuid.uuid4())
                            delete_url = f"{solr_url}/solr/admin/collections?action=DELETEREPLICA&collection={collection_name}&shard={shard_name}&replica={replica_name}&async={request_id}&wt=json"
                            delete_response = http.request('GET', delete_url)
                            delete_result = json.loads(delete_response.data.decode('utf-8'))
                            
                            if delete_result.get('responseHeader', {}).get('status') == 0:
                                if wait_for_async_request(http, solr_url, request_id, timeout=60):
                                    logger.info(f"Deleted recovery_failed replica {collection_name}/{shard_name}/{replica_name}")
                                    pass_deleted.append(f"{collection_name}/{shard_name}/{replica_name}")
                                    
                                    # Only recreate if we're below expected counts
                                    should_recreate = False
                                    target_type = replica_type
                                    
                                    if replica_type == 'NRT' and active_nrt < 1:
                                        should_recreate = True
                                        logger.info(f"Recreating NRT replica (current active: {active_nrt})")
                                    elif replica_type == 'PULL' and active_pull < 2:
                                        should_recreate = True
                                        logger.info(f"Recreating PULL replica (current active: {active_pull})")
                                    else:
                                        logger.info(f"Skipping recreation - sufficient replicas (NRT: {active_nrt}, PULL: {active_pull})")
                                    
                                    if should_recreate:
                                        _recreate_replica(http, solr_url, collection_name, shard_name,
                                                         replica_type, failed_node, live_nodes,
                                                         data_dir, instance_dir, pass_recreated)
                
                # Reload collection immediately after processing it (mimic Solr restart)
                if collection_had_operations:
                    try:
                        reload_url = f"{solr_url}/solr/admin/collections?action=RELOAD&name={collection_name}&wt=json"
                        http.request('GET', reload_url, timeout=30.0)
                        logger.info(f"Reloaded collection {collection_name}")
                        
                        # Wait briefly for collection to stabilize (multi-pass will catch remaining issues)
                        wait_for_collection_healthy(http, solr_url, collection_name, timeout=10)
                    except Exception as e:
                        logger.warning(f"Failed to reload {collection_name}: {e}")
            
            all_deleted.extend(pass_deleted)
            all_recreated.extend(pass_recreated)
            all_recovered.extend(pass_recovered)
            
            # If no failures found, stop
            if not pass_deleted and not pass_recovered:
                logger.info(f"No recovery_failed replicas found in pass {pass_num + 1}, stopping")
                break
            
            logger.info(f"Pass {pass_num + 1} complete: recovered {len(pass_recovered)}, deleted {len(pass_deleted)}, recreated {len(pass_recreated)}")
            
        except Exception as e:
            logger.error(f"Recovery pass {pass_num + 1} failed: {e}")
            break
    
    logger.info(f"Recovery summary: recovered {len(all_recovered)}, deleted {len(all_deleted)}, recreated {len(all_recreated)}")
    return {'recovered': all_recovered, 'deleted': all_deleted, 'recreated': all_recreated}


def _recreate_replica(http, solr_url, collection_name, shard_name,
                      replica_type, failed_node, live_nodes,
                      data_dir, instance_dir, pass_recreated):
    """Helper to recreate a replica on a healthy node"""
    import uuid
    try:
        target_node = failed_node if failed_node in live_nodes else live_nodes[0]
        request_id = str(uuid.uuid4())
        
        # For NRT replicas, check for existing data on shared EFS (PULL replicas sync from NRT)
        if replica_type == 'NRT':
            existing_data = check_existing_data(http, solr_url, collection_name, shard_name)
            if existing_data and existing_data['numDocs'] > 0:
                data_dir = existing_data.get('dataDir')
                instance_dir = existing_data.get('instanceDir')
                logger.info(f"Using existing NRT data with {existing_data['numDocs']} documents from {data_dir}")
        
        # Build ADDREPLICA URL with dataDir and instanceDir if available
        add_url = f"{solr_url}/solr/admin/collections?action=ADDREPLICA&collection={collection_name}&shard={shard_name}&node={target_node}&type={replica_type}&async={request_id}"
        if data_dir:
            add_url += f"&dataDir={data_dir}"
            logger.info(f"Recreating replica with existing dataDir: {data_dir}")
        if instance_dir:
            add_url += f"&instanceDir={instance_dir}"
            logger.info(f"Recreating replica with existing instanceDir: {instance_dir}")
        add_url += "&wt=json"
        
        add_response = http.request('GET', add_url)
        add_result = json.loads(add_response.data.decode('utf-8'))
        
        if add_result.get('responseHeader', {}).get('status') == 0:
            if wait_for_async_request(http, solr_url, request_id, timeout=300):
                logger.info(f"Recreated replica for {collection_name}/{shard_name} on {target_node}")
                pass_recreated.append(f"{collection_name}/{shard_name}")
    except Exception as e:
        logger.error(f"Failed to recreate replica for {collection_name}/{shard_name}: {e}")
