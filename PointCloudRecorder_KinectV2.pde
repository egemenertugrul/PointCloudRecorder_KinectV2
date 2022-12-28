import org.openkinect.processing.*;
import java.util.Date;

// Kinect Library object
Kinect2 kinect2, kinect2b;

// Angle for rotation
float rot = 135;
int skip = 3;
int showDevice = 0;
int strokeWidth = 2;
String showDeviceTxt = "None";

long initTime;
String mainPath;
String subPath_0 = "/Cam1/", subPath_1 = "/Cam2/";
boolean isRecording = false;

void setup() {
  size(800, 600, P3D);
  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initRegistered();
  kinect2.initDevice(0);

  kinect2b = new Kinect2(this);
  kinect2b.initDepth();
  kinect2b.initRegistered();
  kinect2b.initDevice(1);
}

PrintWriter output, outputb;

void draw() {
  Date date = new Date();

  int dataLen = kinect2.depthWidth * kinect2.depthHeight;

  //println(date.getTime());
  if (isRecording) {
    output = createWriter(mainPath +  subPath_0 + date.getTime() + ".ply");
    outputb = createWriter(mainPath + subPath_1 + date.getTime() + ".ply");
    output.println("ply\nformat ascii 1.0\nelement vertex "
      + str(dataLen) +
      "\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header");
    outputb.println("ply\nformat ascii 1.0\nelement vertex "
      + str(dataLen) +
      "\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header");
  }


  background(0);

  // Translate and rotate
  pushMatrix();
  rotateY(rot);

  // We're just going to calculate and draw every 2nd pixel

  // Get the raw depth as array of integers
  int[] depth = kinect2.getRawDepth();
  PImage img = kinect2.getRegisteredImage();

  int[] depthb = kinect2b.getRawDepth();
  PImage imgb = kinect2b.getRegisteredImage();

  stroke(255);
  strokeWeight(strokeWidth);
  beginShape(POINTS);
  // Device 1
  {

    for (int x = 0; x < kinect2.depthWidth; x+=skip) {
      for (int y = 0; y < kinect2.depthHeight; y+=skip) {
        int offset = x + y * kinect2.depthWidth;
        int d = depth[offset];
        //calculte the x, y, z camera position based on the depth information
        PVector point = depthToPointCloudPos(x, y, d);
        color c = img.pixels[offset];

        if (showDevice == 1) {
          vertex(point.x, point.y, point.z);
          stroke(c);
        }

        var red_c = (int) red(c);
        var green_c = (int) green(c);
        var blue_c = (int) blue(c);
        if (isRecording && point.x != 0 && point.y != 0 && point.z != 0 && red_c != 0 && green_c != 0 && blue_c != 0) {
          output.println(point.x + " " + point.y + " " + point.z + " " + red_c + " " + green_c + " " + blue_c);
        }
      }
    }
  }
  // Device 2
  {
    for (int x = 0; x < kinect2b.depthWidth; x+=skip) {
      for (int y = 0; y < kinect2b.depthHeight; y+=skip) {
        int offset = x + y * kinect2b.depthWidth;
        int d = depthb[offset];
        //calculte the x, y, z camera position based on the depth information
        PVector point = depthToPointCloudPos(x, y, d);
        color c = imgb.pixels[offset];

        if (showDevice == 2) {
          vertex(point.x, point.y, point.z);
          stroke(c);
        }

        var red_c = (int) red(c);
        var green_c = (int) green(c);
        var blue_c = (int) blue(c);
        if (isRecording && point.x != 0 && point.y != 0 && point.z != 0 && red_c != 0 && green_c != 0 && blue_c != 0) {
          outputb.println(point.x + " " + point.y + " " + point.z + " " + red_c + " " + green_c + " " + blue_c);
        }
      }
    }
  }

  endShape();
  popMatrix();

  color to = color(255, 144, 144);
  color from = color(144, 255, 144);
  color lerp = lerpColor(from, to, 60 - frameRate - 30);
  fill(lerp);

  text("FPS: " + frameRate, 50, 50);

  fill(255);
  if (isRecording) {
    if ((int) second() % 2 == 0) {
      fill(255, 144, 144);
    }
    text("Duration: " + (date.getTime() - initTime) / 1000f, 200, 65);
  }
  text("Is Recording: " + isRecording + " (Spacebar)", 50, 65);
  fill(255);
  if (showDevice > 0) {
    fill(144, 144, 255);
  }
  text("Showing: " + showDeviceTxt + " (1/2/3)", 50, 80);
  fill(255);
  text("Get every: " + skip + " (Arrow UP/DOWN)", 50, 95);
  fill(255);
  text("Stroke width: " + strokeWidth + " (Arrow LEFT/RIGHT)", 50, 110);


  if (isRecording) {
    output.flush();  // Writes the remaining data to the file
    output.close();  // Finishes the file

    outputb.flush();  // Writes the remaining data to the file
    outputb.close();  // Finishes the file
  }
  // Rotate
  //rot += 0.0015;
}

void keyPressed() {
  if (key==ESC) {
    key=0;
    println("Exiting..");

    if (isRecording) {
      output.flush();  // Writes the remaining data to the file
      output.close();  // Finishes the file

      outputb.flush();  // Writes the remaining data to the file
      outputb.close();  // Finishes the file
    }

    //stop();
    exit();
  }

  if (key==' ') {
    isRecording = !isRecording;
    if (isRecording) {
      Date date = new Date();
      initTime = date.getTime();
      mainPath = "/recordings/" + initTime + "/";
    }
  }

  if (key == CODED) {

    if (keyCode == UP) {
      skip += 1;
      skip = constrain(skip, 1, 10);
    }
    if (keyCode == DOWN) {
      skip -= 1;
      skip = constrain(skip, 1, 10);
    }

    if (keyCode == RIGHT) {
      strokeWidth += 1;
      strokeWidth = constrain(strokeWidth, 1, 10);
    }
    if (keyCode == LEFT) {
      strokeWidth -= 1;
      strokeWidth = constrain(strokeWidth, 1, 10);
    }
  }

  if (key=='1') {
    showDeviceTxt = "None";
    println(showDeviceTxt);
    showDevice = 0;
  }

  if (key=='2') {
    showDeviceTxt = "Device 0";
    println(showDeviceTxt);
    showDevice = 1;
  }

  if (key=='3') {
    showDeviceTxt = "Device 1";
    println(showDeviceTxt);
    showDevice = 2;
  }
}

// calculate the xyz camera position based on the depth data
PVector depthToPointCloudPos(int x, int y, float depthValue) {
  PVector point = new PVector();
  point.z = (depthValue);// / (1.0f); // Convert from mm to meters
  point.x = (x - CameraParams.cx) * point.z / CameraParams.fx;
  point.y = (y - CameraParams.cy) * point.z / CameraParams.fy;
  return point;
}
