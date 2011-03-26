/*
 Run Conway's Game of life on a 5x7 LED Matrix
 
 The 5 rows of the LED matrix are connected directly
 to arduino pins, while the 7 columns are controlled
 by a 74HC595 shift register.
*/

// shift register pins
#define DATA 6
#define CLOCK 5
#define LATCH 4

#define D_ROWS 5
#define D_COLS 7

// How do we handle the border of the field?
enum {
	B_DEAD,
	B_ALIVE,
	B_WRAPPED,
} border_type = B_WRAPPED;

enum {
	// load a predefined configuration on start
	S_PRESET,
	// populate the field randomly
	S_RANDOM
} seed_style = S_PRESET;

// pins controlling the rows
const int rows[D_ROWS] = {
	12,
	11,
	10,
	9,
	8
};

int active_row = 0;

// when did we last update the ecosphere
unsigned long lastrun;
// update the positions every _ milliseconds
int tick = 300;

int current = 0;
boolean field[2][D_ROWS][D_COLS];

void clear_field() {
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			field[current][x][y] = false;
		}
	}
}

int active_preset = 1;
#define N_PRESETS 2
// a nice starting configuration
const bool seed_preset[N_PRESETS][D_ROWS][D_COLS] = {
	{ // nice flower
		{ 0, 0, 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 1, 0, 0, 0 },
		{ 0, 1, 1, 1, 0, 0, 0 },
		{ 0, 0, 0, 1, 0, 0, 0 },
		{ 0, 0, 0, 0, 0, 0, 0 },
	},
	{ // glider
		{ 0, 0, 0, 0, 0, 0, 0 },
		{ 0, 0, 1, 0, 0, 0, 0 },
		{ 0, 0, 0, 1, 0, 0, 0 },
		{ 0, 1, 1, 1, 0, 0, 0 },
		{ 0, 0, 0, 0, 0, 0, 0 },
	},
};

int reseeds = 0;

void seed_field() {
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			if (seed_style == S_PRESET) {
				// mirror the y axis to reflect the presentation in the source
				field[current][x][D_COLS-1-y] = seed_preset[active_preset][x][(y+reseeds)%D_COLS];
			} else if (seed_style == S_RANDOM) {
				field[current][x][y] = (random(6)==0) ? true : false;
			}
		}
	}
	reseeds++;
}

int cells_alive() {
	int n = 0;
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			if (field[current][x][y]) {
				n++;
			}
		}
	}
	return n;
}

short neighbours(int x, int y, boolean f[D_ROWS][D_COLS]) {
	int n = 0;
	for (int dx=-1; dx<=+1; dx++) {
		for (int dy=-1; dy<=+1; dy++) {
			if (dx == 0 && dy == 0) continue;
			if (border_type == B_DEAD) {
				if (x+dx >= D_ROWS || x+dx < 0);
				else if (y+dy >= D_COLS || y+dy < 0);
				else if (f[x+dx][y+dy]) n++;
			} else if (border_type == B_ALIVE) {
				if (x+dx >= D_ROWS || x+dx < 0) n++;
				else if (y+dy >= D_COLS || y+dy < 0) n++;
				else if (f[x+dx][y+dy]) n++;
			} else if (border_type == B_WRAPPED) {
				// make sure x+dx and y+dy are > 0
				if (f[(D_ROWS+x+dx)%D_ROWS][(D_COLS+y+dy)%D_COLS]) n++;
			}
		}
	}
	return n;
}

int update_field() {
	int changes = 0;
	int next = 1 - current;
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			// calculate number of neihgbours
			int n = neighbours(x,y,field[current]);
			// a living cell dies if it has less than 2 neighbours
			if (n<2 && field[current][x][y]) {
				field[next][x][y] = false;
				changes++;
			// a living cell dies if it has more than 3 neighbours
			} else if (n>3 && field[current][x][y]) {
				field[next][x][y] = false;
				changes++;
			// a dead cell comes alive if it has exactly 3 neighbours
			} else if (n == 3 && ! field[current][x][y]) {
				field[next][x][y] = true;
				changes++;
			} else {
				field[next][x][y] = field[current][x][y];
			}
		}
	}
	current = next;
	return changes;
}

void load_line(byte line) {
	digitalWrite(LATCH, LOW);
	shiftOut(DATA, CLOCK, MSBFIRST, ~(line));
	digitalWrite(LATCH, HIGH);
}

void setup() { 
	for (int i=0; i<D_ROWS; i++) {
		pinMode(rows[i], OUTPUT);  
	}

	pinMode(A0, INPUT);

	pinMode(DATA, OUTPUT);
	pinMode(CLOCK, OUTPUT);
	pinMode(LATCH, OUTPUT);

	randomSeed(analogRead(A0));

	clear_field();
	seed_field();
}

void loop() {
	int val = analogRead(A0);

	int line = 0;
	for (int y=0; y<D_COLS; y++) {
		if (field[current][active_row][y]) {
			line |= B1<<y;
		}
	}
	load_line(line);

	digitalWrite(rows[active_row], HIGH);
	delay(1);
	digitalWrite(rows[active_row], LOW);  
	
	// advance to next line
	active_row = (active_row+1) % D_ROWS;

	// update the ecosystem
	if (active_row == 0 && millis() > lastrun+tick) {
		int changes = update_field();
		if ( changes == 0 ) {
			// no cells actually changed their states - BORING!
			// reseed the table once a stable configuration is found
			seed_field();
		}
		lastrun = millis();
	}
}
