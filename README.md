# Point Cloud / Volumetric Recorder

**Point Cloud Recorder (PCR)** is a tool for recording series of .PLY files as point clouds / volumetric videos.

PCR uses [shiffman/OpenKinect-for-Processing](https://github.com/shiffman/OpenKinect-for-Processing). Tested on Processing 4.1.1 and Windows 10.

![](https://i.imgur.com/vtqY33x.gif)

# Installation
1. Follow the instructions [here](https://github.com/shiffman/OpenKinect-for-Processing#kinect-v2-requirements).

2. Install Open Kinect for Processing library.

![](https://i.imgur.com/i50IeXb.png)

3. Clone this repository and run `PointCloudRecorder_KinectV2.pde`.

# Usage

**FPS:** ~60 is desired.

**Is Recording (Spacebar):** Shows recording state and duration. Turns off device preview when activated to increase performance.

**Get every (Arrow UP/DOWN):** Increase/decrease recording fidelity. Reduces recording performance if the value is low. Has effect on the recording.

**Stroke width (Arrow LEFT/RIGHT):** Changes the visualization of points. Has no effect on the recording.
