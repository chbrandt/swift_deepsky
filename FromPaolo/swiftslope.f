      PROGRAM swiftslope
c
c Converts Swift hardness ratio into power law energy slope
c
      IMPLICIT none
      REAL*4 hardness, hard_error, nh, alpha
      REAL*4 aerrplus, aerrminus, hardness_plus, hardness_minus
      REAL*4 alpha_plus, alpha_minus, cr_soft, cr_soft_err
      REAL*4 cr_hard, cr_hard_err

      write (*,
     &  '('' Enter count rate and error in 0.3-2.0 keV band '',$)')
      read (*,*)  cr_soft, cr_soft_err
      write (*,
     & '('' Enter count rate and error in 2.0-10.0 keV band '',$)')
      read (*,*)  cr_hard, cr_hard_err
c      read (*,*) hardness, hard_error
      write (*,'('' Enter  NH '',$)')
      read (*,*) nh
      hardness=cr_hard/cr_soft
      hard_error=
     & sqrt(cr_hard_err**2.+hardness**2.*cr_soft_err**2.)/cr_soft
      write (*,*) ' '
c      write (*,*) ' hardness, error ', hardness, hard_error
      call swift_hardconvert (hardness,nh,alpha)
      hardness_plus=hardness+hard_error
      hardness_minus=hardness-hard_error
      call swift_hardconvert (hardness_plus,nh,alpha_minus)
      call swift_hardconvert (hardness_minus,nh,alpha_plus)
      aerrplus = alpha_plus - alpha
      aerrminus = alpha - alpha_minus
      write (*,'(''                    - '',f4.2)') aerrminus
      write (*,'('' energy index='',f5.2)') alpha
      write (*,'(''                    + '',f4.2)') aerrplus
      end

      SUBROUTINE swift_hardconvert(hardness,nh,alpha)
      implicit none
      INTEGER*4 i , j , k , lu_input , igood , itime
      REAL*4 nh , alpha , hardness , test , testmin
      REAL*4 en(41) , nhvalue(20) , hrgood(41)
      REAL*4 hratio(41,20)
      LOGICAL ok
      if (nh.eq.-99.) then
        alpha=-99.
        return
      endif
      itime = 1
      IF ( itime.EQ.1 ) THEN
c         CALL getlun(lu_input)
         lu_input=10
         OPEN (lu_input,FILE='/work/bin/swifthard03_20_20_10.dat',
     &       STATUS='old')
         READ (lu_input,*,END=100) (nhvalue(j),j=1,20)
         i = 0
         ok = .TRUE.
         DO 50 WHILE (ok)
            i = i + 1
            READ (lu_input,*,END=100) en(i) , (hratio(i,j),j=1,20)
 50      CONTINUE
 100     CLOSE (lu_input)
c         CALL frelun(lu_input)
      ENDIF
      k = 1
      DO 600 WHILE (nh.GE.nhvalue(k).AND.k.LT.20)
         k = k + 1
 600  CONTINUE
      DO 700 i = 1 , 41
            hrgood(i) = (hratio(i,k)-hratio(i,k-1))
     &                  /(nhvalue(k)-nhvalue(k-1))*(nh-nhvalue(k-1))
     &                   + hratio(i,k-1)
 700  CONTINUE
      testmin = 1.E30
      DO 800 i = 1 , 41
         test = abs(hardness-hrgood(i))
         IF ( test.LT.testmin ) THEN
            testmin = test
            alpha = en(i)
            igood = i
         ENDIF
 800  CONTINUE
      IF ( igood.LE.1 .OR. igood.GE.50 ) THEN
         alpha = -99.
      ELSEIF ( hardness.GT.hrgood(igood) ) THEN
         alpha = (en(igood+1)-en(igood))/(hrgood(igood+1)-hrgood(igood))
     &           *(hardness-hrgood(igood)) + en(igood)
      ELSE
         alpha = (en(igood)-en(igood-1))/(hrgood(igood)-hrgood(igood-1))
     &           *(hardness-hrgood(igood-1)) + en(igood-1)
      ENDIF
      RETURN
      END
