import java.awt.Toolkit;

// Credit: https://gist.github.com/GorgeousOne/d6f6faec66ab3aac55258b846794b0b0

/* Example Project
OrbitCamera cam;
void settings() { 
  size(1200, 800, P3D);
  smooth();
}
void setup() {
  cam = new OrbitCamera();
  fill(128);
}
void draw() {
  background(255);
  lights();
  cam.update();
  pushMatrix();
  cam.applyRotation();
  box(100);
  popMatrix();
}
*/

final static float screenDPI = Toolkit.getDefaultToolkit().getScreenResolution();
final static float spinThreshhold = 0.0001;

OrbitCamera singelton;

class OrbitCamera {

  //last recorded windows dimensions
  int pheight;
  int pwidth;

  //current camera properties
  PVector centerPos;
  float viewPlaneDist;
  float fov;
  float defaultRadius;
  float radius;
  float zoom;
  float yaw;
  float pitch;
  boolean isYUp;

  //properties the camera will transition to smoothly
  PVector targetCenterPos;
  float targetZoom;
  float targetYaw;
  float targetPitch;
  
  float mouseSensitivity;
  boolean stateChanged;
  
  OrbitCamera() {
    singelton = this;
    centerPos = new PVector(0, 0, 0);
    targetCenterPos = new PVector();
    setFOV(60);
    setTargetZoom(1);
    zoom = .8f;
    setMouseSensitivity(.8f);
    setYUp(true);
    setDefaultRadius(100);
    stateChanged = true;
    update();
  }
  
  PVector getEyePos() {
    return new PVector(
        radius * sin(-yaw) * cos(pitch),
        radius * sin(pitch),
        radius * cos(-yaw) * cos(pitch)).sub(this.centerPos);
  }

  /**
   * Calculates the direction the camera is looking towards.
   */
  PVector getDir() {
        return new PVector(
            sin(-yaw) * -cos(pitch),
            -sin(pitch),
            cos(-yaw) * -cos(pitch));
  }
  
  /**
   * Calculates the up vector of the camera.
   */
  PVector getUp() {
    return new PVector(
        sin(-yaw) * sin(pitch),
        -cos(pitch),
        cos(-yaw ) * sin(pitch)).mult((isYUp ? -1 : 1));
  }
  
  /**
   * Sets the center point for the camera
   */
  void setTargetPos(PVector v) {
    targetCenterPos.set(v);
  }
  
  void shiftTargetPos(PVector delta) {
    targetCenterPos.add(delta);  
  }
  
  /*
   * Aligns the camera target yaw & pitch to the x axis.
   * Rotates the camera by 180° if it is already aligned with the x axis.
   */ 
  void alignX() {
    if (targetYaw == -HALF_PI && targetPitch == 0) {
      targetYaw = HALF_PI;
    } else {
      targetYaw = -HALF_PI;
      targetPitch = 0;      
    }
  }
  
  void alignY() {
    if (targetYaw == 0 && targetPitch == HALF_PI) {
      targetPitch = -HALF_PI;
    } else {
      targetPitch = HALF_PI;      
      targetYaw = 0;
    }
  }

  void alignZ() {    
    if (targetYaw == 0 && targetPitch == 0) {
      targetYaw = PI;
    } else {
      targetYaw = 0;
      targetPitch = 0;      
    }
  }
  
   /**
   * Sets wether the y axis in the scene should be facing up or down (by default down)
   */
  void setYUp(boolean state) {
    isYUp = state;
    stateChanged = true;
  }

  /**
   * Sets the default radius of the camera (the radius if the zoom set to 1x)
   */
  void setDefaultRadius(float radius) {
    defaultRadius = radius;
    radius = defaultRadius / zoom;
  }
  
  void setFOV(float fov) {
    this.fov = max(30, min(120, fov));
    this.stateChanged = true;
  }
  
  void setTargetZoom(float zoom) {
    this.targetZoom = zoom;
  }

  void setYaw(float yaw) {
    this.yaw = yaw;
  }
  
  void setPitch(float pitch) {
    this.pitch = pitch;
  }  
  
  void setMouseSensitivity(float sensitivity) {
    this.mouseSensitivity = sensitivity;
  }
  
  boolean windowSizeChanged() {
     return pheight != height || pwidth != width;
  }
  
  /**
   * Adapts the camera to changes in window size or property changes
   */
  void update() {
    if (windowSizeChanged() || stateChanged) {
      float radFOV =  PI * fov / 180;
      float aspectRatio = 1f * width / height;
      viewPlaneDist = .5f * min(width, height) / tan(.5f * radFOV);
      
      perspective(radFOV, aspectRatio, 1, viewPlaneDist * 10); 
      camera(0, 0, 0, 0, 0, -1, 0, isYUp ? -1 : 1, 0);
      
      pheight = height;
      pwidth = width;
      stateChanged = false;
    }
  }
  
  /**
   * Applies the camera rotation to the scene and updates rotational changes by the mouse
   */
  void applyRotation() {
    float dYaw = targetYaw - yaw;
    float dPitch = targetPitch - pitch;
    float transitionSpeed = .2f;
    
    yaw += dYaw * transitionSpeed;
    pitch += dPitch * transitionSpeed;
    
    PVector delta = targetCenterPos.copy().sub(centerPos);
    centerPos.add(delta.mult(transitionSpeed));
    
    float dZoom = targetZoom - zoom;  
    if (abs(dZoom) > 0.001) {
      zoom += dZoom * transitionSpeed;
      radius = defaultRadius / zoom;
    }else if (dZoom != 0) {
      zoom = targetZoom;
      radius = defaultRadius / zoom;
    }
    translate(0, 0, -radius);
    rotateX(pitch);
    rotateY(yaw);
    translate(centerPos.x, centerPos.y, centerPos.z);
  }
  
  /**
   * Calculates new target yaw & pitch by given mouse movement
   * @param dx delta x mouse movement
   * @param dy delty y mouse movement
   */
  void rotateTargetAxes(int dx, int dy) {
    int direction = isYUp ? -1 : 1;
    
    float dYaw = mouseSensitivity * dx / screenDPI * direction;
    float dPitch = mouseSensitivity * dy / screenDPI * direction;
    
    targetYaw += dYaw;
    targetPitch = max(-HALF_PI, min(HALF_PI, targetPitch - dPitch));
  }
  
  /**
   * Calculates new target pos by given mouse movement
   * @param dx delta x mouse movement
   * @param dy delty y mouse movement
   */
  void shiftTargetPos(int dx, int dy) {
    PVector dirY = singelton.getUp();
    PVector dirX = dirY.cross(singelton.getDir());
    shiftTargetPos(
        dirX.mult(dx)
        .add(dirY.mult(-dy))
        .mult(mouseSensitivity / zoom * (.0015f * defaultRadius)));
  }
  
  /**
   * Increases or decreses the target zooms by mouse wheel steps
   */
  void addScrollToTargetZoom(int scrollCount) {
     targetZoom = max(0.5, min(8, targetZoom + scrollCount / 2f));
  }
}

//registers mouse clicks and wheel movement
void handleMouseEvent(MouseEvent event) {
  super.handleMouseEvent(event);
  int action = event.getAction();

  if (action == MouseEvent.DRAG) {
    int dx = mouseX - pmouseX;
    int dy = mouseY - pmouseY;
    
    if (event.getButton() == LEFT) {
      singelton.rotateTargetAxes(dx, dy);
    }else if (event.getButton() == RIGHT) {
      singelton.shiftTargetPos(dx, dy);
    }
  }else if (action == MouseEvent.WHEEL) {
    singelton.addScrollToTargetZoom(-event.getCount());
  }
}

void handleKeyEvent(KeyEvent event) {
  super.handleKeyEvent(event);

  if (event.getAction() != KeyEvent.PRESS) {
    return;  
  }
  switch(key) {
    case 'c':
      singelton.setTargetPos(new PVector());
      break;
    case 'x':
      singelton.alignX();
      break;
    case 'y':
      singelton.alignY();
      break;
    case 'z':
      singelton.alignZ();
      break;
  }
}

void testCamera() {
  OrbitCamera cam = new OrbitCamera();  
  cam.yaw = 0;
  cam.pitch = 0;
  assert(isSimilar(new PVector(0, 0, -1), cam.getDir()));
  assert(isSimilar(new PVector(0, -1, 0), cam.getUp()));
  
  cam.yaw = HALF_PI;
  cam.pitch = 0;
  assert(isSimilar(new PVector(1, 0, 0), cam.getDir()));
  assert(isSimilar(new PVector(0, -1, 0), cam.getUp()));

  cam.yaw = HALF_PI;
  cam.pitch = HALF_PI;
  assert(isSimilar(new PVector(0, -1, 0), cam.getDir()));
  assert(isSimilar(new PVector(-1, 0, 0), cam.getUp()));

  cam.yaw = 0;
  cam.pitch = -QUARTER_PI;
  println(cam.getDir(), cam.getUp());
  assert(isSimilar(new PVector(0, 0.7071, -0.7071), cam.getDir()));
  assert(isSimilar(new PVector(0, -0.7071, -0.7071), cam.getUp()));

}

boolean isSimilar(PVector v0, PVector v1) {
  float epsilon = 0.001f;
  return 
      abs(v1.x - v0.x) < epsilon &&
      abs(v1.y - v0.y) < epsilon &&
      abs(v1.z - v0.z) < epsilon;
}
