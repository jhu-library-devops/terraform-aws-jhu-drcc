import boto3
import time
import logging

logger = logging.getLogger()
ssm = boto3.client('ssm')

LOCK_PARAMETER = '/dspace/solr-rollover/lock'
LOCK_TIMEOUT = 1800  # 30 minutes (increased from 15)

def acquire_lock(force_recovery=False):
    """Attempt to acquire execution lock with improved recovery"""
    try:
        # Try to create parameter (fails if exists)
        ssm.put_parameter(
            Name=LOCK_PARAMETER,
            Value=str(int(time.time())),
            Type='String',
            Overwrite=False
        )
        logger.info("Lock acquired")
        return True
    except ssm.exceptions.ParameterAlreadyExists:
        # Check if lock is stale or force recovery requested
        try:
            response = ssm.get_parameter(Name=LOCK_PARAMETER)
            lock_time = int(response['Parameter']['Value'])
            current_time = time.time()
            lock_age = current_time - lock_time
            
            if force_recovery:
                logger.warning(f"Force recovery requested, breaking lock (age: {lock_age:.0f}s)")
                release_lock()
                return acquire_lock()
            elif lock_age > LOCK_TIMEOUT:
                logger.warning(f"Stale lock detected (age: {lock_age:.0f}s > {LOCK_TIMEOUT}s), breaking it")
                release_lock()
                return acquire_lock()
            else:
                remaining = LOCK_TIMEOUT - lock_age
                logger.error(f"Another rollover is in progress (remaining: {remaining:.0f}s)")
                return False
        except Exception as e:
            logger.error(f"Error checking lock: {e}")
            return False
    except Exception as e:
        logger.error(f"Error acquiring lock: {e}")
        return False

def release_lock():
    """Release execution lock"""
    try:
        ssm.delete_parameter(Name=LOCK_PARAMETER)
        logger.info("Lock released")
    except ssm.exceptions.ParameterNotFound:
        pass
    except Exception as e:
        logger.error(f"Error releasing lock: {e}")
