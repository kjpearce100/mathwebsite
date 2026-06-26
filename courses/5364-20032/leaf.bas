RANDOMIZE TIMER

READ n
FOR i = 1 TO n
       READ a(i), b(i), e(i), c(i), d(i), f(i)
NEXT i

REM INPUT "Enter initial point x,y: ", x, y
x = .5: y = .5

SCREEN (12)
WINDOW (-.1, -.1)-(1.1, 1.1)


WHILE (INKEY$ = "")
        PSET (x, y), 2
        GOSUB newpoint
WEND

END

newpoint:
        j = INT(n * RND) + 1
        GOSUB calc
RETURN

calc:
        u = (a(j) * x + b(j) * y) + e(j)
        v = (c(j) * x + d(j) * y) + f(j)
        x = u: y = v
RETURN

DATA 4
DATA .20, -.26, .400, .23, .22,  .045
DATA .85, .04, 0.075, -.04, .85,  .180
DATA 0, 0, .50, 0, .16,  0
DATA -.15, .28, .575, .26, .24,  -.086

