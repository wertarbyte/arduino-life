/*
 Run Conway's Game of life on a 5x7 LED Matrix
 
 The 5 rows of the LED matrix are connected directly
 to arduino pins, while the 7 columns are controlled
 by a 74HC595 shift register.

 Wiring instructions:

    Arduino  6       -> 74HC595 14 (DATA)
    Arduino  5       -> 74HC595  9 (CLOCK)
    Arduino  4       -> 74HC595 12 (LATCH)

    Arduino 12       -> Matrix  1 (Row 1)
    Arduino 11       -> Matrix  3 (Row 2)
    Arduino 10       -> Matrix  9 (Row 3)
    Arduino  9       -> Matrix  8 (Row 4)
    Arduino  8       -> Matrix  7 (Row 5)

    74HC595 15 (Q0)  -> Matrix 12 (Col 1)
    74HC595  1 (Q1)  -> Matrix 11 (Col 2)
    74HC595  2 (Q2)  -> Matrix  2 (Col 3)
    74HC595  3 (Q3)  -> Matrix  9 (Col 4)
    74HC595  4 (Q4)  -> Matrix  4 (Col 5)
    74HC595  5 (Q5)  -> Matrix  5 (Col 6)
    74HC595  6 (Q6)  -> Matrix  6 (Col 7)

    74HC959  8 (GND) -> +5V
    74HC959 10 (MR)  -> +5V
    74HC959 13 (OE)  -> GND
    74HC959 16 (VCC) -> GND

    A button is connected to port 7.

*/

// shift register pins
#define DATA 6
#define CLOCK 5
#define LATCH 4

#define BTN 7

#define D_ROWS 5
#define D_COLS 7

// How do we handle the border of the field?
enum border_type {
	B_DEAD,
	B_ALIVE,
	B_WRAPPED,
};

enum seed_style {
	// load a predefined configuration on start
	S_PRESET,
	// populate the field randomly
	S_RANDOM
};

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

int btn_state = 0;

int current = 0;
boolean field[2][D_ROWS][D_COLS];

void clear_field() {
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			field[current][x][y] = false;
		}
	}
}

typedef struct {
	border_type border;
	seed_style seed;
	bool field[D_ROWS][D_COLS];
} preset;

#include <presets.h>

static inline const preset *get_preset() {
	return &presets[active_preset];
}

int reseeds = 0;

void seed_field() {
	const preset *ps = get_preset();
	for (int x=0; x < D_ROWS; x++) {
		for (int y=0; y < D_COLS; y++) {
			if (ps->seed == S_PRESET) {
				// mirror the y axis to reflect the presentation in the source
				field[current][x][D_COLS-1-y] = ps->field[x][(y+reseeds)%D_COLS];
			} else if (ps->seed == S_RANDOM) {
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
	const preset *ps = get_preset();
	int n = 0;
	for (int dx=-1; dx<=+1; dx++) {
		for (int dy=-1; dy<=+1; dy++) {
			if (dx == 0 && dy == 0) continue;
			if (ps->border == B_DEAD) {
				if (x+dx >= D_ROWS || x+dx < 0);
				else if (y+dy >= D_COLS || y+dy < 0);
				else if (f[x+dx][y+dy]) n++;
			} else if (ps->border == B_ALIVE) {
				if (x+dx >= D_ROWS || x+dx < 0) n++;
				else if (y+dy >= D_COLS || y+dy < 0) n++;
				else if (f[x+dx][y+dy]) n++;
			} else if (ps->border == B_WRAPPED) {
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

void configure() {
	active_preset = 2;
#include <config.h>
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

	configure();

	clear_field();
	seed_field();
}

void loop() {
	int new_state = digitalRead(BTN);
	if (new_state == 1 && btn_state == 0) {
		// advance to next preset
		clear_field();
		active_preset = (active_preset+1)%N_PRESETS;
		seed_field();
		delay(100);
	}
	btn_state = new_state;

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
