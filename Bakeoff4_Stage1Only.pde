import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import ketai.camera.*;

KetaiSensor sensor;
KetaiCamera cam;
PImage bg, snapshot, mux;

float cursorX, cursorY;
float light = 0; 
float proxSensorThreshold = 10; //you will need to change this per your device.

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

int camWidth = 1280;
int camHeight = 760;

// color recognized in current region
// r = red, b = blue, g = green, k = black
char centerColor = 'n';


void setup() {
  //size(1080, 1920); //you can change this to be fullscreen
  //frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();

  // CAMERA STUFF
  orientation(LANDSCAPE);
  cam = new KetaiCamera(this, camWidth, camHeight, 30);
  imageMode(CENTER);
  cam.start();

  rectMode(CENTER);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);
  

  for (int i=0; i<trialCount; i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }

  Collections.shuffle(targets); // randomize the order of the button;
}

void draw() {
  int index = trialIndex;

  //uncomment line below to see if sensors are updating
  //println("light val: " + light +", cursor accel vals: " + cursorX +"/" + cursorY);
  background(80); //background is light grey
  noStroke(); //no stroke

  countDownTimerWait--;

  if (cam.isStarted()) {
    image(cam, width/2, height/2);
    //cam.loadPixels();
    
    // classify as black
    if (centerColor == 'k') {
      fill(0, 0, 0);
      text("BLACK", width/2, height-100);
    }
    // classify as red
    else if (centerColor == 'r') {
      fill(255, 0, 0);
      text("RED", width/2, height-100);
    }
    // classify as green
    else if (centerColor == 'g') {
      fill(0, 255, 0);
      text("GREEN", width/2, height-100);
    }
    // classify as blue
    else {
      fill(0, 0, 255);
      text("BLUE", width/2, height-100);
    }
  }

  if (startTime == 0)
    startTime = millis();

  if (index>=targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount, 1) + " sec per target", width/2, 150);
    return;
  }

  //for (int i=0; i<4; i++)
  //{
  //  if (targets.get(index).target==i)
  //    fill(0, 255, 0);
  //  else
  //    fill(180, 180, 180);
  //  ellipse(300, i*150+100, 100, 100);
  //}

  //if (light>proxSensorThreshold)
  //  fill(180, 0, 0);
  //else
  //  fill(255, 0, 0);
  //ellipse(cursorX, cursorY, 50, 50);

  if (targets.get(index).target == 0) {
    fill(0, 0, 0); 
    text("show me BLACK", width/2, 150);
  }
  else if (targets.get(index).target == 1) {
    fill(255, 0, 0); 
    text("show me RED", width/2, 150);
  }
  if (targets.get(index).target == 2) {
    fill(0, 255, 0); 
    text("show me GREEN", width/2, 150);
  }
  else if (targets.get(index).target == 3) {
    fill(0, 0, 255); 
    text("show me BLUE", width/2, 150);
  }


  fill(255);//white
  text("Trial " + (index+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(index).target)+1, width/2, 100);

  //if (targets.get(index).action==0)
  //  text("UP", width/2, 150);
  //else
  //  text("DOWN", width/2, 150);
}


void onCameraPreviewEvent() {
  cam.read();
  
  if (cam.isStarted()) {
    cam.loadPixels();
    
    float R = 0;
    float G = 0;
    float B = 0;
    
    // only consider center half of image
    int centerMinCol = camWidth/2 - camWidth/4;
    int centerMaxCol = camWidth/2 + camWidth/4;
    int centerMinRow = camHeight/2 - camHeight/4;
    int centerMaxRow = camHeight/2 + camHeight/4;
    int centerNumPx = (centerMaxRow - centerMinRow) * (centerMaxCol - centerMinCol);
    
    // draw rectangle around center region
    //rect(width/2 - 
    
    // find avg rgb of center
    for (int r = centerMinRow; r < centerMaxRow; r++) {
      for (int c = centerMinCol; c < centerMaxCol; c++) {
        color currColor = cam.pixels[r*camWidth + c];
        R += red(currColor);
        G += green(currColor);
        B += blue(currColor);
      }
    }
    
    R = R / centerNumPx;
    G = G / centerNumPx;
    B = B / centerNumPx;
      
    println(R, G, B); 
    
    // classify as black
    if (R < 150 && G < 150 && B < 150) {
      centerColor = 'k';
    }
    // classify as red
    else if (R > G && R > B) {
      centerColor = 'r';
    }
    // classify as green
    else if (G > R && G > B) {
      centerColor = 'g';
    }
    // classify as blue
    else {
      centerColor = 'b';
    }
    
    int index = trialIndex;

    if (userDone || index>=targets.size())
      return;
  
    //if (light>proxSensorThreshold) //only update cursor, if light is low
    //{
    //  cursorX = 300+x*40; //cented to window and scaled
    //  cursorY = 300-y*40; //cented to window and scaled
    //}

    Target t = targets.get(index);
  
    if (t==null)
      return;
    println(light);
    if (light <= proxSensorThreshold && centerColor != 'n') {
      println("it's dark in here!\n");
      if (colorHitTest(centerColor) == t.target) {
        println("got the correct color!\n");
        trialIndex++;
      }
      else {
        if (trialIndex > 0) {
          trialIndex--;
          println("got the wrong color...");
        }
      }
      
      countDownTimerWait = 60;
    }
   
  //  if (light<=proxSensorThreshold && abs(z-9.8)>4 && countDownTimerWait<0) //possible hit event
  //  {
  //    if (hitTest()==t.target)//check if it is the right target
  //    {
  //      //println(z-9.8); use this to check z output!
  //      if (((z-9.8)>4 && t.action==0) || ((z-9.8)<-4 && t.action==1))
  //      {
  //        println("Right target, right z direction!");
  //        trialIndex++; //next trial!
  //      } else
  //      {
  //        if (trialIndex>0)
  //          trialIndex--; //move back one trial as penalty!
  //        println("right target, WRONG z direction!");
  //      }
  //      countDownTimerWait=30; //wait roughly 0.5 sec before allowing next trial
  //    } 
  //  } else if (light<=proxSensorThreshold && countDownTimerWait<0 && hitTest()!=t.target)
  //  { 
  //    println("wrong round 1 action!"); 
  
  //    if (trialIndex>0)
  //      trialIndex--; //move back one trial as penalty!
  
  //    countDownTimerWait=30; //wait roughly 0.5 sec before allowing next trial
  //  }
  }
}

// 0 = black, 1 = red, 2 = green, 3 = blue
int colorHitTest(char c) {
  if (c == 'k') return 0;
  else if (c == 'r') return 1;
  else if (c == 'g') return 2;
  else if (c == 'b') return 3;
  else return -1;
}


void onAccelerometerEvent(float x, float y, float z)
{
  int index = trialIndex;

  if (userDone || index>=targets.size())
    return;

  if (light>proxSensorThreshold) //only update cursor, if light is low
  {
    cursorX = 300+x*40; //cented to window and scaled
    cursorY = 300-y*40; //cented to window and scaled
  }

  Target t = targets.get(index);

  if (t==null)
    return;
 
  if (light<=proxSensorThreshold && abs(z-9.8)>4 && countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      //println(z-9.8); use this to check z output!
      if (((z-9.8)>4 && t.action==0) || ((z-9.8)<-4 && t.action==1))
      {
        println("Right target, right z direction!");
        trialIndex++; //next trial!
      } else
      {
        if (trialIndex>0)
          trialIndex--; //move back one trial as penalty!
        println("right target, WRONG z direction!");
      }
      countDownTimerWait=30; //wait roughly 0.5 sec before allowing next trial
    } 
  } else if (light<=proxSensorThreshold && countDownTimerWait<0 && hitTest()!=t.target)
  { 
    println("wrong round 1 action!"); 

    if (trialIndex>0)
      trialIndex--; //move back one trial as penalty!

    countDownTimerWait=30; //wait roughly 0.5 sec before allowing next trial
  }
}

int hitTest() 
{
  for (int i=0; i<4; i++)
    if (dist(300, i*150+100, cursorX, cursorY)<100)
      return i;

  return -1;
}


void onLightEvent(float v) //this just updates the light value
{
  light = v;
}
