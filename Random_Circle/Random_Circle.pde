int squareSize = 1;
int screen_width = 700;
int screen_height = 700;
int random_low = -10;
int random_high = 10;

void settings() {
  size(screen_width, screen_height);
}

void setup() {
  frameRate(30);
  colorMode(RGB, 255, 255, 255);
  background(0);
  strokeWeight(0);
}

void draw() {
  background(0);
  
  for (int i = 0; i < 10000; i = i+1) {
    float r1 = random(random_low, random_high);
    float r2 = random(random_low, random_high);
    float r3 = random(random_low, random_high);
    float r4 = random(random_low, random_high);
    
    float center_x = screen_width / 2;
    float center_y = screen_height / 2;
    
    float leng1 = r1 * r2;
    float leng2 = r3 * r4;
    
    float x = center_x + sin(leng1) * leng1;
    float y = center_y + cos(leng1) * leng1;
    
    square(x, y, squareSize);
  }
}
