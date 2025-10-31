import java.io.File;


ArrayList<Ball> balls;

// Scene boundaries
float groundY, ceilingY;
float leftWall, rightWall;
float nearWall, farWall;

// Textures
PImage[] textures;
String[] textureNames;

// Counters & constants
int ballCounter = 0;
final float GRAVITY = 0.5;
final float DAMPING_FACTOR = 0.85;
final float SPIN_DAMPING = 0.98;

void loadTextures() {
  // Load all image files in the "data/" folder automatically
  File dataFolder = new File(dataPath(""));
  File[] files = dataFolder.listFiles();

  ArrayList<PImage> texList = new ArrayList<PImage>();
  ArrayList<String> nameList = new ArrayList<String>();

  if (files != null) {
    for (File f : files) {
      String fname = f.getName().toLowerCase();
      if (fname.endsWith(".jpg") || fname.endsWith(".png") || fname.endsWith(".jpeg")) {
        PImage tex = loadImage(f.getName());
        if (tex != null) {
          texList.add(tex);
          nameList.add(f.getName());
          println("Loaded texture: " + f.getName());
        } else {
          println("Failed to load " + f.getName());
        }
      }
    }
  } else {
    println("No texture files found in data/ directory!");
  }

  textures = texList.toArray(new PImage[0]);
  textureNames = nameList.toArray(new String[0]);

  println("Loaded " + textures.length + " textures from data/");
}


void setup() {
  size(800, 600, P3D);
  initEnvironment();
  loadTextures();
}

void displayBallStats() {
  int totalBalls = balls.size();
  int movingBalls = 0;

  // --- Count total & moving ---
  for (Ball b : balls) {
    if (!b.isStopped()) movingBalls++;
  }

  // --- Count per texture ---
  HashMap<String, Integer> textureCount = new HashMap<String, Integer>();
  for (Ball b : balls) {
    textureCount.put(b.textureName, textureCount.getOrDefault(b.textureName, 0) + 1);
  }

  // --- Draw text overlay ---
  camera();
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(16);
  textAlign(LEFT, TOP);

  int y = 10;
  text(" Total Balls: " + totalBalls, 10, y);
  y += 20;
  text(" Fast-moving Balls: " + movingBalls, 10, y);
  y += 30;

  text("Texture Counts:", 10, y);
  y += 20;

  for (String name : textureCount.keySet()) {
    text("     " + name + ": " + textureCount.get(name), 20, y);
    y += 18;
  }

  hint(ENABLE_DEPTH_TEST);
}


// =======================================================
// Main draw loop
// =======================================================
void draw() {
  background(30);
  setupCamera();
  drawBoundaries();
  setupLighting();
  updateAndRenderBalls();

  displayBallStats();
}

// =======================================================
// Initialization Helpers
// =======================================================

void initEnvironment() {
  balls = new ArrayList<Ball>();

  // Define 3D boundaries
  groundY = 200;
  ceilingY = -200;
  leftWall = -400;
  rightWall = 400;
  nearWall = 0;
  farWall = -800;
}


// =======================================================
// Scene Rendering
// =======================================================

void setupCamera() {
  camera(width / 2.0, height / 2.0, (height / 2.0) / tan(PI * 30.0 / 180.0),
         width / 2.0, height / 2.0, 0,
         0, 1, 0);
}

void setupLighting() {
  lights();
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 0.5, -1);
}

void drawBoundaries() {
  pushMatrix();
  translate(width/2, height/2, 0);
  noStroke();
  noLights();
  hint(DISABLE_DEPTH_TEST);

  drawQuad(leftWall, rightWall, groundY, groundY, nearWall, farWall, color(0, 255, 100, 100));   // Floor
  drawQuad(leftWall, rightWall, ceilingY, ceilingY, nearWall, farWall, color(100, 200, 255, 100)); // Ceiling
  drawWall(leftWall, color(255, 100, 100, 100));  // Left wall
  drawWall(rightWall, color(255, 100, 255, 100)); // Right wall
  drawZWall(farWall, color(100, 100, 255, 100));  // Far wall
  drawZWall(nearWall, color(255, 255, 100, 100)); // Near wall

  hint(ENABLE_DEPTH_TEST);
  popMatrix();
}

void drawQuad(float x1, float x2, float y1, float y2, float z1, float z2, int c) {
  fill(c);
  beginShape(QUADS);
  vertex(x1, y1, z1);
  vertex(x2, y2, z1);
  vertex(x2, y2, z2);
  vertex(x1, y1, z2);
  endShape(CLOSE);
}

void drawWall(float x, int c) {
  fill(c);
  beginShape(QUADS);
  vertex(x, ceilingY, nearWall);
  vertex(x, groundY, nearWall);
  vertex(x, groundY, farWall);
  vertex(x, ceilingY, farWall);
  endShape(CLOSE);
}

void drawZWall(float z, int c) {
  fill(c);
  beginShape(QUADS);
  vertex(leftWall, ceilingY, z);
  vertex(rightWall, ceilingY, z);
  vertex(rightWall, groundY, z);
  vertex(leftWall, groundY, z);
  endShape(CLOSE);
}

// =======================================================
// Ball Management
// =======================================================

void updateAndRenderBalls() {
  for (int i = balls.size() - 1; i >= 0; i--) {
    Ball ball = balls.get(i);
    ball.update();
    ball.checkWallCollisions();
    ball.display();

    for (int j = i - 1; j >= 0; j--) {
      ball.checkBallCollision(balls.get(j));
    }

    if (ball.isStopped()) {
      // balls.remove(i); // Optional cleanup
    }
  }
}

void mousePressed() {
  PVector pos = new PVector(mouseX - width / 2, mouseY - height / 2, nearWall);
  PVector vel = new PVector(random(-5, 5), random(-8, -3), random(-25, -15));

  int tIndex = int(random(textures.length));
  PImage tex = textures[tIndex];
  String texName = textureNames[tIndex];

  ballCounter++;
  Ball newBall = new Ball(pos, vel, tex, ballCounter, texName);
  balls.add(newBall);
  logBallCreation(newBall);
}

void logBallCreation(Ball b) {
  println("========================================");
  println("Ball #" + b.ballNumber + " Generated");
  println("Texture: " + b.textureName);
  println("Location: " + b.position);
  println("Velocity: " + b.velocity);
  println("========================================");
}

class Ball {
  PVector position, velocity, rotation, rotationSpeed;
  float radius = 35;
  float mass = 1.0;
  int ballNumber, bounceCount = 0;
  float totalTime = 0;
  boolean onGround = false;
  PImage texture;
  PShape globe;
  String textureName;

  Ball(PVector pos, PVector vel, PImage tex, int number, String texName) {
    position = pos.copy();
    velocity = vel.copy();
    rotation = new PVector(0, 0, 0);
    rotationSpeed = calcInitialRotation(velocity);
    texture = tex;
    textureName = texName;
    ballNumber = number;
    createGlobe();
  }

  void createGlobe() {
    globe = createShape(SPHERE, radius);
    globe.setTexture(texture);
    globe.setStroke(false);
  }

  PVector calcInitialRotation(PVector vel) {
    return new PVector(-vel.z * 0.1, vel.x * 0.1, vel.y * 0.05);
  }

  void update() {
    velocity.y += GRAVITY;
    position.add(velocity);
    rotation.add(rotationSpeed);
    rotationSpeed.mult(SPIN_DAMPING);
    totalTime++;
    velocity.mult(0.999);
  }

  void checkWallCollisions() {
    boolean bounced = false;
    bounced |= collideY(groundY,  1);
    bounced |= collideY(ceilingY, -1);
    bounced |= collideX(leftWall,  1);
    bounced |= collideX(rightWall, -1);
    bounced |= collideZ(nearWall, -1);
    bounced |= collideZ(farWall,   1);

    if (bounced) updateRotationAfterBounce();
  }

  boolean collideY(float wallY, int dir) {
    if (dir == 1 && position.y + radius > wallY) { // Ground
      position.y = wallY - radius;
      velocity.y *= -DAMPING_FACTOR;
      onGround = abs(velocity.y) < 0.5;
      bounceCount++;
      return true;
    } else if (dir == -1 && position.y - radius < wallY) { // Ceiling
      position.y = wallY + radius;
      velocity.y *= -DAMPING_FACTOR;
      bounceCount++;
      return true;
    }
    return false;
  }

  boolean collideX(float wallX, int dir) {
    if (dir == 1 && position.x - radius < wallX) {
      position.x = wallX + radius;
      velocity.x *= -DAMPING_FACTOR;
      bounceCount++;
      return true;
    } else if (dir == -1 && position.x + radius > wallX) {
      position.x = wallX - radius;
      velocity.x *= -DAMPING_FACTOR;
      bounceCount++;
      return true;
    }
    return false;
  }

  boolean collideZ(float wallZ, int dir) {
    if (dir == 1 && position.z - radius < wallZ) {
      position.z = wallZ + radius;
      velocity.z *= -DAMPING_FACTOR;
      bounceCount++;
      return true;
    } else if (dir == -1 && position.z + radius > wallZ) {
      position.z = wallZ - radius;
      velocity.z *= -DAMPING_FACTOR;
      bounceCount++;
      return true;
    }
    return false;
  }

  void updateRotationAfterBounce() {
    rotationSpeed = calcInitialRotation(velocity);
  }

  void checkBallCollision(Ball other) {
    PVector diff = PVector.sub(position, other.position);
    float dist = diff.mag();
    float minDist = radius + other.radius;

    if (dist < minDist && dist > 0) {
      diff.normalize();
      PVector relVel = PVector.sub(velocity, other.velocity);
      float velAlongNormal = relVel.dot(diff);
      if (velAlongNormal > 0) return;

      float impulse = -(1 + DAMPING_FACTOR) * velAlongNormal / (1/mass + 1/other.mass);
      PVector impulseVec = PVector.mult(diff, impulse);

      velocity.add(PVector.div(impulseVec, mass));
      other.velocity.sub(PVector.div(impulseVec, other.mass));

      float overlap = minDist - dist;
      PVector separation = PVector.mult(diff, overlap / 2);
      position.add(separation);
      other.position.sub(separation);

      updateRotationAfterBounce();
      other.updateRotationAfterBounce();

      bounceCount++;
      other.bounceCount++;
    }
  }

  void display() {
    pushMatrix();
    translate(position.x + width/2, position.y + height/2, position.z);
    rotateX(rotation.x);
    rotateY(rotation.y);
    rotateZ(rotation.z);
    shape(globe);
    popMatrix();
  }

  boolean isStopped() {
  boolean nearlyOnGround = position.y + radius >= groundY - 1;
  boolean slowEnough = velocity.mag() < 1.0;
  boolean rotationSlow = rotationSpeed.mag() < 0.05;
  return nearlyOnGround && slowEnough && rotationSlow;  
}
}
