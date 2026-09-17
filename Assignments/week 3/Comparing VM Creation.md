# Comparing VM Creation

Starting a virtual machine locally, launching an instance on Jetstream 2, and provisioning a bare-metal instance on Chameleon Cloud provided different experiences in setup time, resource allocation, and networking. The main distinction was between using the computer's existing resources, requesting on-demand cloud resources, and reserving dedicated physical hardware.

## Local Virtual Machine

Local virtualization offered a quick and convenient environment for isolated testing. Once the required image was available, starting and accessing the VM did not depend on connecting to a remote cloud service. However, the resources available to the VM were limited by the host computer's CPU, memory, and storage, and running it added to the computer's workload.

The local workflow focused on configuring the guest environment rather than managing cloud networking. It did not require the floating IP allocation and cloud security group configuration used in the remote environments. This made local virtualization convenient for smaller experiments, although its capacity remained tied to the host hardware.

## Jetstream 2

Jetstream 2 provided a relatively quick, on-demand cloud VM workflow. During the setup, instances became available within minutes, and launching them did not require reserving a physical node in advance. Selecting an available cloud image and an appropriate instance size made the process straightforward.

Networking required more attention than the local setup. Assigning a floating IP address and configuring security group rules were necessary for SSH connectivity in the workflow used. Once those settings were in place, remote access was straightforward. These configuration steps are also described in the [Jetstream 2 launch documentation](https://docs.jetstream-cloud.org/ui/cli/launch/).

## Chameleon Cloud

The Chameleon Cloud environment used for this comparison followed a reservation-based bare-metal workflow rather than a conventional VM workflow. A lease had to be created before launching an instance on the reserved hardware, consistent with the [Chameleon getting-started guide](https://chameleoncloud.readthedocs.io/en/latest/getting-started/).

Provisioning took noticeably longer than the local and Jetstream 2 setups. This made the process feel less immediate and required more advance planning. External access also involved allocating and associating a floating IP address through the web interface before connecting through SSH.

The additional setup effort came with access to dedicated physical hardware, making this environment a better fit for experiments requiring hardware-level control. This experience applies specifically to Chameleon's bare-metal environment; Chameleon also provides a separate [KVM virtual-machine workflow](https://chameleoncloud.readthedocs.io/en/v1.0/technical/kvm.html).

## Overall Comparison

Local virtualization was the most convenient option for quick, isolated testing within the computer's resource limits. Jetstream 2 offered a practical balance between quick provisioning and access to remotely hosted computing resources, although it required cloud networking configuration. Chameleon's bare-metal environment required the most planning and provisioning time but provided dedicated hardware for more specialized systems experiments.

Overall, the preferred platform depends on the task: local VMs suit smaller development exercises, Jetstream 2 suits routine cloud VM deployments, and Chameleon bare metal suits experiments that benefit from direct control over physical resources.
