int connectionInterval;
int slaveLatency;
int hopInterval;
int channel;

int channels;
long time;

int lineheight;
float pixelToTime;
float scaleTime;
int skipped;
boolean advertising=true;

class Event {
  long startTime;
  long duration;
  int type;
  int channel;
}

PImage back, wifi;
PImage[] master, slave;

ArrayList events = new ArrayList();
ArrayList used = new ArrayList();

int[] channelMap = new int[] {
  37,
  0,1,2,3,4,5,6,7,8,9,10,
  38,
  11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,39
}; 

int[] channelMappingGood = new int[]{
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
};

int[] channelMappingBad = new int[]{
  9,10,21,22,23,33,34,35,36,9,10,21,22,23,33,34,35,36,9,10,21,22,23,33,34,35,36,9,10,21,22,23,33,34,35,36,9,10,21,22,23,33,34,35,36
};
int[] channelMapping = channelMappingGood;

int[] channelIndex = new int[channelMap.length];
int[] adaptiveChannels = new int[]{
  0,1,2,3,4,5,6,7,8,9,
  10,11,12,13,14,15,16,17,18,19,20,
  21,22,23,24,25,26,27,28,29,30,
  31,32,33,34,35,36,37,38,39
};




void setup() {
  back = loadImage("btle_channels.png");
  wifi = loadImage("wifi_channels.png");
  master = new PImage[]{
    loadImage("master_left.png"),
    loadImage("master_center.png"),
    loadImage("master_right.png")
  };
  slave = new PImage[]{
    loadImage("slave_left.png"),
    loadImage("slave_center.png"),
    loadImage("slave_right.png")
  };
  
  channel = 2;
  
  channels = 40;
  lineheight = 1200/channels;
  slaveLatency = 3;
  
  connectionInterval = 30000;
  scaleTime = 50f;
  
  hopInterval = 4;
  skipped = slaveLatency;
  
  size(1920, channels*lineheight + 1);
  
  pixelToTime = width/(float)(20*connectionInterval);
  
  for (int i=0; i<channelMap.length; i++) {
    channelIndex[channelMap[i]] = i; 
  }
  
  channelMappingBad[37] = 37;
  channelMappingBad[38] = 38;
  channelMappingBad[39] = 39;
}

int advertisingChannel;
long nextConnectionEvent;
void updateEventQueue(float time) {
  //println(time);
  if (nextConnectionEvent<=time) {
    
    if (speed!=null) {
      if (speed==Boolean.TRUE) {
        slaveLatency++;
      } else {
        slaveLatency = max(slaveLatency-1, 0);
      }
      speed = null;
    } 
    
    int durationSlave;
    int durationMaster;
    int chan;
    int conIn;
    
    if (advertising) {
      chan = advertisingChannel + 37;
      durationMaster = 35000;
      durationSlave = 5000; 
      if (advertisingChannel==2) {
        conIn = durationMaster+durationSlave+100000;
      } else {
        conIn = durationMaster+durationSlave+150+200;
      }
      advertisingChannel = (advertisingChannel +1 ) % 3;
      
    } else {
      durationMaster = durationSlave = 5000;
      channel = (channel+hopInterval)%37;
      chan = channel;
      conIn = connectionInterval;
    }
    
    Event w = new Event();
    w.duration = durationMaster;
    w.startTime = nextConnectionEvent;
    w.channel = chan;
    w.type = 1;
    events.add(w);
    
    if (skipped++>=slaveLatency || advertising) {
      skipped = 0;
      w = new Event();
      w.duration = durationSlave;
      w.startTime = nextConnectionEvent + durationMaster + 150;
      w.channel = chan;
      w.type = 0;
      events.add(w);
    }
    nextConnectionEvent += conIn;
    
  }
  
}

long currentTime, lastMillis;
boolean running = true;
boolean showWifi = false;
Boolean speed;
void keyPressed() {
  if (keyCode==' ') {
    running = !running;
    if (running) {
      lastMillis = millis();
       
      loop();
    } else {
      noLoop();
    }
  }
  if (key=='a') {
    advertising = !advertising;
  }
  if (key=='w') {
    showWifi = !showWifi;
    channelMapping = showWifi ? channelMappingBad : channelMappingGood;
    redraw();
  }
  if (key=='+') {
    speed = Boolean.TRUE;
  }
  if (key=='-') {
    speed = Boolean.FALSE;
  }
}

void draw() {
  background(0x80);
  scale(0.5);
  if (running) {
    long now = millis();
    currentTime += millis()-lastMillis;
    lastMillis = now;
  } else {
    lastMillis = millis();
  }
  float time = currentTime*scaleTime; // in micro
  
  updateEventQueue(time);
  
  image(back,0,0);
  if (showWifi)
    image(wifi,0,0);
  
  used.clear();
  // Now draw events
  for (int i=0; i<events.size(); i++) {
    Event e = (Event)events.get(i);
    
    int top = 4 + channelIndex[channelMapping[adaptiveChannels[e.channel]]]*lineheight;
    int left = width-(int)((time-e.startTime) * pixelToTime);
    int w = (int)(e.duration * pixelToTime);
    if (w+left>0) {
      if (w<width) {
        noStroke();
        PImage[] ie = master;
        if (e.type==0) {
          ie = slave;
        }
        
        image(ie[0], left, top);
        image(ie[1], left+4, top, w-8, 24);
        image(ie[2], left + w - 4, top);
        
      }
      used.add(e);
    }    
  }
  
  // Swap event buffers
  ArrayList tmp = events;
  events = used;
  used = tmp;
  
  
  fill(255);
  String text = "Time " + time + "\u00B5s"; 
  text(text, width-textWidth(text), 30);
}

