import boto3
import csv
from datetime import datetime

def deregister_ami_and_delete_snapshots(csv_file_path):
    ec2 = boto3.client('ec2')
    
    # Define the cutoff date (January 1, 2024)
    cutoff_date = datetime(2024, 1, 1)

    with open(csv_file_path, 'r') as file:
        reader = csv.reader(file)
        # Skip the header
        next(reader)

        for row in reader:
            ami_id = row[0]

            # Get AMI information to retrieve creation date and snapshot ids
            try:
                ami_info = ec2.describe_images(ImageIds=[ami_id])['Images'][0]
                creation_date = datetime.strptime(ami_info['CreationDate'], '%Y-%m-%dT%H:%M:%S.%fZ')

                # Only proceed if the AMI was created before the cutoff date
                if creation_date < cutoff_date:
                    block_device_mappings = ami_info['BlockDeviceMappings']

                    print(f"Deregistering AMI: {ami_id} (Created on {creation_date})")
                    ec2.deregister_image(ImageId=ami_id)

                    for block_device in block_device_mappings:
                        if 'Ebs' in block_device:
                            snapshot_id = block_device['Ebs']['SnapshotId']
                            
                            # Check if snapshot is in use
                            snapshot_info = ec2.describe_snapshots(SnapshotIds=[snapshot_id])['Snapshots'][0]
                            if snapshot_info['State'] == 'completed':  # Only delete completed snapshots
                                print(f"Deleting Snapshot: {snapshot_id}")
                                ec2.delete_snapshot(SnapshotId=snapshot_id)
                            else:
                                print(f"Skipping active snapshot: {snapshot_id}")
                else:
                    print(f"Skipping AMI {ami_id} (Created on {creation_date}), as it was created after 01/01/2024")

            except Exception as e:
                print(f"Error processing AMI {ami_id}: {e}")

# Provide the path to your CSV file here
csv_file_path = 'path_to_your_ami_ids.csv'
deregister_ami_and_delete_snapshots(csv_file_path)