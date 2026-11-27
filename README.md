# Unitree RL Lab

[![IsaacSim](https://img.shields.io/badge/IsaacSim-5.1.0-silver.svg)](https://docs.omniverse.nvidia.com/isaacsim/latest/overview.html)
[![Isaac Lab](https://img.shields.io/badge/IsaacLab-2.3.0-silver)](https://isaac-sim.github.io/IsaacLab)
[![License](https://img.shields.io/badge/license-Apache2.0-yellow.svg)](https://opensource.org/license/apache-2-0)
[![Discord](https://img.shields.io/badge/-Discord-5865F2?style=flat&logo=Discord&logoColor=white)](https://discord.gg/ZwcVwxv5rq)


## Overview

This project provides a set of reinforcement learning environments for Unitree robots, built on top of [IsaacLab](https://github.com/isaac-sim/IsaacLab).

Currently supports Unitree **Go2**, **H1** and **G1-29dof** robots.

<div align="center">

| <div align="center"> Isaac Lab </div> | <div align="center">  Mujoco </div> |  <div align="center"> Physical </div> |
|--- | --- | --- |
| [<img src="https://oss-global-cdn.unitree.com/static/d879adac250648c587d3681e90658b49_480x397.gif" width="240px">](g1_sim.gif) | [<img src="https://oss-global-cdn.unitree.com/static/3c88e045ab124c3ab9c761a99cb5e71f_480x397.gif" width="240px">](g1_mujoco.gif) | [<img src="https://oss-global-cdn.unitree.com/static/6c17c6cf52ec4e26bbfab1fbf591adb2_480x270.gif" width="240px">](g1_real.gif) |

</div>

## Installation

- Install Isaac Lab by following the [installation guide](https://isaac-sim.github.io/IsaacLab/main/source/setup/installation/index.html).
- Install the Unitree RL IsaacLab standalone environments.

  - Clone or copy this repository separately from the Isaac Lab installation (i.e. outside the `IsaacLab` directory):

    ```bash
    git clone https://github.com/unitreerobotics/unitree_rl_lab.git
    ```
  - Use a python interpreter that has Isaac Lab installed, install the library in editable mode using:

    ```bash
    conda activate env_isaaclab
    ./unitree_rl_lab.sh -i
    # restart your shell to activate the environment changes.
    ```
- Download unitree robot description files

  *Method 1: Using USD Files*
  - Download unitree usd files from [unitree_model](https://huggingface.co/datasets/unitreerobotics/unitree_model/tree/main), keeping folder structure
    ```bash
    git clone https://huggingface.co/datasets/unitreerobotics/unitree_model
    ```
  - Config `UNITREE_MODEL_DIR` in `source/unitree_rl_lab/unitree_rl_lab/assets/robots/unitree.py`.

    ```bash
    UNITREE_MODEL_DIR = "</home/user/projects/unitree_usd>"
    ```

  *Method 2: Using URDF Files [Recommended]* Only for Isaacsim >= 5.0
  -  Download unitree robot urdf files from [unitree_ros](https://github.com/unitreerobotics/unitree_ros)
      ```
      git clone https://github.com/unitreerobotics/unitree_ros.git
      ```
  - Config `UNITREE_ROS_DIR` in `source/unitree_rl_lab/unitree_rl_lab/assets/robots/unitree.py`.
    ```bash
    UNITREE_ROS_DIR = "</home/user/projects/unitree_ros/unitree_ros>"
    ```
  - [Optional]: change *robot_cfg.spawn* if you want to use urdf files



- Verify that the environments are correctly installed by:

  - Listing the available tasks:

    ```bash
    ./unitree_rl_lab.sh -l # This is a faster version than isaaclab
    ```
  - Running a task:

    ```bash
    ./unitree_rl_lab.sh -t --task Unitree-G1-29dof-Velocity # support for autocomplete task-name
    # same as
    python scripts/rsl_rl/train.py --headless --task Unitree-G1-29dof-Velocity
    ```
  - Inference with a trained agent:

    ```bash
    ./unitree_rl_lab.sh -p --task Unitree-G1-29dof-Velocity # support for autocomplete task-name
    # same as
    python scripts/rsl_rl/play.py --task Unitree-G1-29dof-Velocity
    ```

## Deploy

After the model training is completed, we need to perform sim2sim on the trained strategy in Mujoco to test the performance of the model.
Then deploy sim2real.

### Setup

```bash
# Install dependencies
sudo apt install -y libyaml-cpp-dev libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev
# Install unitree_sdk2
git clone git@github.com:unitreerobotics/unitree_sdk2.git
cd unitree_sdk2
mkdir build && cd build
cmake .. -DBUILD_EXAMPLES=OFF # Install on the /usr/local directory
sudo make install
# Compile the robot_controller
cd unitree_rl_lab/deploy/robots/g1_29dof # or other robots
mkdir build && cd build
cmake .. && make
```

### Sim2Sim

Installing the [unitree_mujoco](https://github.com/unitreerobotics/unitree_mujoco?tab=readme-ov-file#installation).

- Set the `robot` at `/simulate/config.yaml` to g1
- Set `domain_id` to 0
- Set `enable_elastic_hand` to 1
- Set `use_joystck` to 1.

```bash
# start simulation
cd unitree_mujoco/simulate/build
./unitree_mujoco
# ./unitree_mujoco -i 0 -n eth0 -r g1 -s scene_29dof.xml # alternative
```

```bash
cd unitree_rl_lab/deploy/robots/g1_29dof/build
./g1_ctrl
# 1. press [L2 + Up] to set the robot to stand up
# 2. Click the mujoco window, and then press 8 to make the robot feet touch the ground.
# 3. Press [R1 + X] to run the policy.
# 4. Click the mujoco window, and then press 9 to disable the elastic band.
```

### Sim2Real

You can use this program to control the robot directly, but make sure the on-borad control program has been closed.

```bash
./g1_ctrl --network eth0 # eth0 is the network interface name.
```

### ExecuTorch (optional)

The controller can also run a policy with [ExecuTorch](https://github.com/pytorch/executorch), PyTorch's solution for deploying models on devices. A policy keeps running its `policy.onnx` with ONNX Runtime unless its config names a `.pte` file.

1. Build the controller with ExecuTorch. The build needs CMake 3.28 or newer and the C++ library inside the ExecuTorch Python package (ExecuTorch 1.6.0 needs Python 3.11 or newer). The library is all the build needs, so on the robot install the package without its dependencies:

   ```bash
   pip install --no-deps executorch==1.6.0
   cmake .. -DUSE_EXECUTORCH=ON -DCMAKE_PREFIX_PATH="$(python -c 'import executorch, pathlib; print(pathlib.Path(executorch.__path__[0]) / "share" / "cmake")')"
   make
   ```

   The controller loads the library from that Python environment every time it starts. Keep the environment, and rebuild the controller after changing the ExecuTorch version in it. ONNX Runtime stays linked, for the policies that still run `policy.onnx`.

2. Export the policy to `exported/policy.pte`, next to its `policy.onnx`. The program takes the same inputs as `policy.onnx`, and stores their names in an `input_names` constant method, in the order `forward()` takes them. The `export_policy_to_executorch` exporter proposed for rsl_rl in [rsl_rl#271](https://github.com/leggedrobotics/rsl_rl/pull/271) writes such programs. It is not in a released rsl_rl yet, and it targets a newer rsl_rl than the one Isaac Lab 2.3 installs. To export directly, use a Python environment other than the Isaac Lab one, because `pip install executorch==1.6.0 onnx` brings torch 2.15.0. This example rebuilds the actor network from the weights in a `policy.onnx`, either one shipped in this repo or one that `play.py` wrote. Run it from the folder that holds `exported/`, for example `deploy/robots/g1_29dof/config/policy/velocity/v0`:

   ```python
   import onnx
   import torch
   from onnx import numpy_helper
   from torch import nn
   from executorch.backends.xnnpack.partition.xnnpack_partitioner import XnnpackPartitioner
   from executorch.exir import to_edge_transform_and_lower

   model = onnx.load("exported/policy.onnx")
   assert {n.op_type for n in model.graph.node} == {"Gemm", "Elu"}, "this example only rebuilds an ELU actor without an observation normalizer"
   state = {t.name: torch.from_numpy(numpy_helper.to_array(t).copy()) for t in model.graph.initializer}
   num_obs, num_actions = state["actor.0.weight"].shape[1], state["actor.6.weight"].shape[0]

   # The actor from rsl_rl_ppo_cfg.py: actor_hidden_dims=[512, 256, 128], activation="elu", no observation normalization.
   policy = nn.Sequential(
       nn.Linear(num_obs, 512), nn.ELU(),
       nn.Linear(512, 256), nn.ELU(),
       nn.Linear(256, 128), nn.ELU(),
       nn.Linear(128, num_actions),
   )
   policy.load_state_dict({k.removeprefix("actor."): v for k, v in state.items()})
   policy.eval()

   program = to_edge_transform_and_lower(
       torch.export.export(policy, (torch.zeros(1, num_obs),)),
       partitioner=[XnnpackPartitioner()],
       constant_methods={"input_names": ["obs"]},
   ).to_executorch()
   with open("exported/policy.pte", "wb") as f:
       f.write(program.buffer)
   ```

   Export the `.pte` again whenever the policy changes. The controller does not check that the `.pte` matches `policy.onnx`.

3. Name the file in the policy's state in `config.yaml`, next to `policy_dir`:

   ```yaml
   policy_dir: config/policy/velocity
   policy_file: exported/policy.pte
   ```

   `policy_file` is relative to the policy folder, which the controller prints at startup as `Policy directory`, and defaults to `exported/policy.onnx`. The controller runs each policy once at startup, so a `.pte` that does not match the observations in `deploy.yaml` stops it there, before the robot moves. A controller built without ExecuTorch stops at startup if a state names a `.pte`.

## Acknowledgements

This repository is built upon the support and contributions of the following open-source projects. Special thanks to:

- [IsaacLab](https://github.com/isaac-sim/IsaacLab): The foundation for training and running codes.
- [mujoco](https://github.com/google-deepmind/mujoco.git): Providing powerful simulation functionalities.
- [robot_lab](https://github.com/fan-ziqi/robot_lab): Referenced for project structure and parts of the implementation.
- [whole_body_tracking](https://github.com/HybridRobotics/whole_body_tracking): Versatile humanoid control framework for motion tracking.
