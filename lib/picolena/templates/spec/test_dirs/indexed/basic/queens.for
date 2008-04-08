      PROGRAM QUEENS
            IMPLICIT NONE
            CHARACTER*2 BOARD(8,8)
            INTEGER X,Y,I
            LOGICAL POSSIBLE
            X=2
            Y=3
            CALL NEW(BOARD) 
            DO I=1,1
                POSSIBLE=.FALSE.
                X=4
                Y=5
C                X=int(rand(0)*8)+1
C                Y=int(rand(0)*8)+1
                CALL TEST(BOARD,X,Y,POSSIBLE)
                IF (POSSIBLE) THEN
                  CALL SET(BOARD,X,Y)
                  CALL RANGED(BOARD,X,Y)
                ENDIF
            ENDDO
            CALL SHOW(BOARD)
      END