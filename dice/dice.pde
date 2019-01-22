import java.util.Random;
import java.awt.event.KeyEvent;
import java.util.Locale;

Random rng;

final color BG_COLOR = color(128);
final color DICE_COLOR = color(0);
final color NUMBER_COLOR = color(0, 128, 255);

static final String advHelpText = "Use the mousewheel to adjust the number of sides per die.\n" +
                  "Use the up/down arrow keys to adjust the number of dice.\n" +
                  "Right-click or press F1 to hide this help message.";
String helpText = "";
                  
static final int MIN_CANVAS_SIZE = 480;
static final int DIE_SIZE = 100;
static final int INTER_DIE_GAP = DIE_SIZE / 10;
static final int MAX_DIE_SIDES = Integer.MAX_VALUE;
static final int MIN_DIE_SIDES = 4;
static final int MAX_DIE_COUNT = 10;
static final int MIN_DIE_COUNT = 1;
static final int DIE_Y_COORD = (480 / 2) - (DIE_SIZE / 2);
static int ADV_HELP_TEXT_HEIGHT;

int currentSides = MIN_DIE_SIDES;
int currentCount = MIN_DIE_COUNT;
boolean showHelp = false;

void setup()
{
  size(480,480);
  background(BG_COLOR);
  surface.setResizable(true);
  rng = new Random(System.currentTimeMillis());
  ADV_HELP_TEXT_HEIGHT = height - (DIE_Y_COORD + DIE_SIZE); //todo too high, should be closer to the bottom of the window
  noStroke();
  generateHelpMsg();
}

void draw(){
  // Must be included in order for live event listeners to fire properly
}

void roll(int num, int sides)
{
  clearScreen();
  int calcSize = (DIE_SIZE * currentCount) + (INTER_DIE_GAP * currentCount + 2);
  surface.setSize(calcSize < MIN_CANVAS_SIZE ? MIN_CANVAS_SIZE : calcSize, 480);
  
  int offset = INTER_DIE_GAP;
  for(int i = 0; i < num; i++){
    drawDie(offset, sides);
    offset += DIE_SIZE + INTER_DIE_GAP;
  }
}

void drawDie(int offset, int sides)
{
  // todo finish
}

void generateHelpMsg()
{  
  fill(BG_COLOR);
  rect(0, 0, width, DIE_Y_COORD - INTER_DIE_GAP);
  helpText = String.format(Locale.ENGLISH, "# of sides: %d\n# of dice: %d", currentSides, currentCount);
  fill(color(0));
  text(helpText, 0, 0, width, DIE_Y_COORD - INTER_DIE_GAP);
}

void clearScreen(){
  background(BG_COLOR);
}

void updateHelp()
{
  if(showHelp){
    fill(color(0));
    text(advHelpText, 0, height - ADV_HELP_TEXT_HEIGHT, width, ADV_HELP_TEXT_HEIGHT);
  }else{
    fill(BG_COLOR);
    rect(0, height - ADV_HELP_TEXT_HEIGHT, width, ADV_HELP_TEXT_HEIGHT); 
  }
}

void mouseClicked()
{
  if(mouseButton == LEFT) roll(currentCount, currentSides);
  else if(mouseButton == RIGHT){
    showHelp = false;
    updateHelp();
  }
}

void mouseWheel(MouseEvent event)
{
  if(event.getCount() > 0) currentSides --;
  else if(event.getCount() < 0) currentSides ++;
  
  currentSides = currentSides > MAX_DIE_SIDES ? MAX_DIE_SIDES : currentSides;
  currentSides = currentSides < MIN_DIE_SIDES ? MIN_DIE_SIDES : currentSides;
  
  generateHelpMsg();
}

void keyPressed()
{ 
  switch(keyCode)
  {
    case KeyEvent.VK_UP:
      currentCount ++;
    break;
    
    case KeyEvent.VK_DOWN:
      currentCount --;
    break;
    
    case KeyEvent.VK_F1:
      showHelp = !showHelp;
      updateHelp();
    break;
    
    case KeyEvent.VK_F24:
      boolean bg_select = false;
      while(true){
        background(bg_select ? color(255, 0, 255) : color(255, 255, 0));
        text("EVERYTHING WENT WRONG OH GOD PLEASE SEND HELP", width / 2, height / 2, 400, 400);
        try{ Thread.sleep(500); }catch(InterruptedException ignored) {}
      }
  }
  
  currentCount = currentCount > MAX_DIE_COUNT ? MAX_DIE_COUNT : currentCount;
  currentCount = currentCount < MIN_DIE_COUNT ? MIN_DIE_COUNT : currentCount;
  
  generateHelpMsg();
}
