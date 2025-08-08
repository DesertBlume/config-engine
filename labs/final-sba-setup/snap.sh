for snap in $(virsh snapshot-list --name linux-cli-vm); do
    virsh snapshot-delete linux-cli-vm "$snap" --metadata
done

