 100 P=32896
 110 DIM K$(3,3)
 120 K$(0,0)="C"
 121 K$(0,1)="D"
 122 K$(0,2)="E"
 123 K$(0,3)="F"
 124 K$(1,0)="8"
 125 K$(1,1)="9"
 126 K$(1,2)="A"
 127 K$(1,3)="B"
 128 K$(2,0)="4"
 129 K$(2,1)="5"
 130 K$(2,2)="6"
 131 K$(2,3)="7"
 132 K$(3,0)="0"
 133 K$(3,1)="1"
 134 K$(3,2)="2"
 135 K$(3,3)="3"
 700 J=1
 710 FOR C=0 TO 3
 720 POKE P,255-J
 730 J=2*J
 740 R=PEEK(P) AND 15
 750 IF R=15 THEN 780
 760 GOSUB 900
 770 PRINT K$(C,R);
 780 NEXT
 790 GOTO 700
 900 IF R=14 THEN R=3
 910 IF R=13 THEN R=2
 920 IF R=11 THEN R=1
 930 IF R=7 THEN R=0
 940 RETURN