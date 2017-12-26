      PROGRAM conv2sedfile
c
c Reads a swift_deepsky flux output file and produces a SED input file  
c
c
      IMPLICIT none
      INTEGER*4 i,rah,ram,dd,dm,im
      INTEGER*4 ier, lu_in, lu_out, lenact, in,length
      REAL*4 mjd,freq1kev, freq, err, one, rasec, dsec, flux, test
      REAL*8 ra, dec
      CHARACTER*1 sign
      CHARACTER*80 input_file,output_file
      CHARACTER*300 string
      LOGICAL there,ok
c
      ok = .TRUE. 
      CALL rdforn(string,length)
      IF ( length.NE.0 ) THEN
         CALL rmvlbk(string)
         input_file= string(1:lenact(string))
      ELSE
         WRITE (*,'('' Enter input file '',$)')
         READ (*,'(a)') input_file
      ENDIF
      lu_in = 10
      lu_out = 11
      INQUIRE (FILE=input_file,EXIST=there)
      IF (.NOT.there) THEN
         write (*,'('' file '',a,'' not found '')')
     &     input_file(1:lenact(input_file))
         STOP
      ENDIF
      open(lu_in,file=input_file,status='old',iostat=ier)
      in = index (input_file,'.')
      output_file=input_file(1:in-1)//'4SED.txt'
      open(lu_out,file=output_file,status='unknown',iostat=ier)
      IF (ier.ne.0) THEN
        write (*,*) ' Error ',ier,' opening file ', input_file
      ENDIF
      string=''
      READ(lu_in,'(a)',end=99) string 
      one = 1.0
      freq1kev = 2.418e17 
      mjd = 55000.0
      sign=''
      DO WHILE(ok)
         READ(lu_in,'(a)',end=99) string 
         in = index(string(1:lenact(string)),';') 
         READ(string(1:in-1),'(i2,x,i2,x,f6.3)') rah,ram,rasec 
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+2:im-1),'(i2,x,i2,x,f6.3)') dd,dm,dsec 
         sign(1:1) = string((in+1):(in+1))
         call chra(ra,rah,ram,rasec,0)
         call chdec(dec,dd,dm,dsec,0)
         IF (sign(1:1) == '-') dec=-dec
         DO i = 1,5
            in = im
            im = index(string(in+1:lenact(string)),';')+in
         ENDDO
         READ(string(in+1:im-1),*) flux 
c        3.0 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err 
         freq = freq1kev*3.0 
         write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                  e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | | '')')
     &                  ra,dec,freq,one,flux,err,mjd,mjd
c        0.5 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) flux
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err
c         print *,' flux err ', flux, err
         freq = freq1kev*0.5
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) test ! test if upper limit
         IF (test < 0. ) THEN 
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ELSE
            flux = test 
            err = 0.
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ENDIF
c        1.5 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) flux
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err
         freq = freq1kev*1.5
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) test ! test if upper limit
         IF (test < 0. ) THEN 
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ELSE
            flux = test 
            err = 0.
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ENDIF
c        4.5 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
c         print *,' in im', in, im
         READ(string(in+1:im-1),*) flux
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err
         freq = freq1kev*4.5
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:lenact(string)),*) test ! test if upper limit
         IF (test < 0. ) THEN 
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ELSE
            flux = test 
            err = 0.
            write(lu_out,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f10.2,'' | '',f10.2,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjd,mjd
         ENDIF
      ENDDO 
 99   CONTINUE
      END
