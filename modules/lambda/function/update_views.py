import boto3
import json
import os
import time
from datetime import datetime

athena_client = boto3.client('athena')

def lambda_handler(event, context):
    """
    Lambda function to update Athena views daily.
    Executes all named queries to recreate views with fresh data.
    """
    
    workgroup = os.environ['ATHENA_WORKGROUP']
    database = os.environ['GLUE_DATABASE']
    output_location = os.environ['ATHENA_OUTPUT_LOCATION']
    named_queries_json = os.environ['NAMED_QUERY_IDS']
    
    # Parse named query IDs
    named_queries = json.loads(named_queries_json)
    
    print(f"Starting view update at {datetime.utcnow().isoformat()}")
    print(f"Workgroup: {workgroup}")
    print(f"Database: {database}")
    print(f"Named queries to execute: {len(named_queries)}")
    
    results = {
        'success': [],
        'failed': [],
        'total': len(named_queries)
    }
    
    for view_name, query_id in named_queries.items():
        try:
            print(f"Processing view: {view_name} (Query ID: {query_id})")
            
            # Get the named query
            response = athena_client.get_named_query(NamedQueryId=query_id)
            query_string = response['NamedQuery']['QueryString']
            
            print(f"Executing query for {view_name}...")
            
            # Execute the query
            execution_response = athena_client.start_query_execution(
                QueryString=query_string,
                QueryExecutionContext={'Database': database},
                ResultConfiguration={'OutputLocation': output_location},
                WorkGroup=workgroup
            )
            
            execution_id = execution_response['QueryExecutionId']
            
            # Wait for query completion
            max_wait = 60  # seconds
            wait_interval = 2  # seconds
            elapsed = 0
            
            while elapsed < max_wait:
                status_response = athena_client.get_query_execution(
                    QueryExecutionId=execution_id
                )
                
                status = status_response['QueryExecution']['Status']['State']
                
                if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                    break
                
                time.sleep(wait_interval)
                elapsed += wait_interval
            
            if status == 'SUCCEEDED':
                print(f"✓ View {view_name} updated successfully")
                results['success'].append({
                    'view': view_name,
                    'execution_id': execution_id
                })
            else:
                error_msg = status_response['QueryExecution']['Status'].get(
                    'StateChangeReason', 'Unknown error'
                )
                print(f"✗ View {view_name} failed: {error_msg}")
                results['failed'].append({
                    'view': view_name,
                    'execution_id': execution_id,
                    'error': error_msg
                })
                
        except Exception as e:
            print(f"✗ Error updating view {view_name}: {str(e)}")
            results['failed'].append({
                'view': view_name,
                'error': str(e)
            })
    
    # Summary
    print(f"\n{'='*50}")
    print(f"View Update Summary")
    print(f"{'='*50}")
    print(f"Total views: {results['total']}")
    print(f"Successful: {len(results['success'])}")
    print(f"Failed: {len(results['failed'])}")
    print(f"Completed at: {datetime.utcnow().isoformat()}")
    
    if results['failed']:
        print(f"\nFailed views:")
        for failed in results['failed']:
            print(f"  - {failed['view']}: {failed.get('error', 'Unknown')}")
    
    return {
        'statusCode': 200 if len(results['failed']) == 0 else 206,
        'body': json.dumps(results),
        'timestamp': datetime.utcnow().isoformat()
    }
