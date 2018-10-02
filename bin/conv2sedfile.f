      PROGRAM conv2sedfile
c
c Reads a swift_deepsky flux output file and produces two input files for the SSDC SED tool
c The file ending with "4SED.txt" includes the spectral points
c The file ending with "4SEDLC.txt" includes the flux interpolated at 1 keV suitable for the SED light curve
c
      IMPLICIT none
      INTEGER*4 i,rah,ram,dd,dm,im,imjd,imjde
      INTEGER*4 ier, lu_in, lu_outSED, lu_outLC, lenact, in,length
      REAL*4 freq1kev, freq, err, one, rasec, dsec, flux, test
      REAL*4 f05,f15,f05err,f15err,f1kev,mjdstart,mjdend
      REAL*8 ra, dec
      CHARACTER*1 sign
      CHARACTER*80 input_file,output_fileSED,output_fileLC
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
      lu_outSED = 11
      lu_outLC = 12
      INQUIRE (FILE=input_file,EXIST=there)
      IF (.NOT.there) THEN
         write (*,'('' file '',a,'' not found '')')
     &     input_file(1:lenact(input_file))
         STOP
      ENDIF
      open(lu_in,file=input_file,status='old',iostat=ier)
      in = index (input_file,'.')
      output_fileSED=input_file(1:in-1)//'4SED.txt'
      open(lu_outSED,file=output_fileSED,status='unknown',iostat=ier)
      output_fileLC=input_file(1:in-1)//'4SEDLC.txt'
      open(lu_outLC,file=output_fileLC,status='unknown',iostat=ier)
      IF (ier.ne.0) THEN
        write (*,*) ' Error ',ier,' opening file ', input_file
      ENDIF
      string=''
      READ(lu_in,'(a)',end=99) string 
      one = 1.0
      freq1kev = 2.418e17 
c      mjd = 55000.0
      sign=''
      DO WHILE(ok)
         READ(lu_in,'(a)',end=99) string 
         in = index(string(1:lenact(string)),';') 
         imjd = in
         DO i = 1,16
            im = imjd
            imjd = index(string(im+1:lenact(string)),';')+im
         ENDDO
         imjde = index(string(imjd+1:lenact(string)),';')+imjd  
c         print *,' imjd imjde ',imjd,imjde
         read(string(imjd+1:imjde-1),*) mjdstart
c         print *,' mjdstart ',mjdstart
         imjde = index(string(imjd+1:lenact(string)),';')+imjd  
         read(string(imjd+1:imjde-1),*) mjdend
         mjdend=mjdstart+mjdend/86400.
c         print *,' mjdend ',mjdstart+mjdend/86400.
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
         write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                  e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | | '')')
     &                  ra,dec,freq,one,flux,err,mjdstart,mjdend
c        0.5 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) flux
         f05 = flux
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err
         f05err = err
c         print *,' flux err ', flux, err
         freq = freq1kev*0.5
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) test ! test if upper limit
         IF (test < 0. ) THEN 
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
         ELSE
            flux = test 
            err = 0.
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
            f05 = -1.
         ENDIF
c        1.5 KeV flux 
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) flux
         f15=flux
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) err
         f15err = err
         freq = freq1kev*1.5
         in = im
         im = index(string(in+1:lenact(string)),';')+in
         READ(string(in+1:im-1),*) test ! test if upper limit
         IF (test < 0. ) THEN 
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
            IF ( f05 > 0. ) THEN  ! no upper limits 
              f1kev=(f15-f05)/(1.5-0.5)*(1.-0.5)+f05
              err = (f05err+f15err)/2.
              write(lu_outLC,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | | '')')
     &                     ra,dec,freq1kev,one,f1kev,err,mjdstart,mjdend
            ENDIF
         ELSE
            flux = test 
            err = 0.
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
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
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
         ELSE
            flux = test 
            err = 0.
            write(lu_outSED,'(f10.5,'' | '',f10.5,'' | '',e10.4,'' | '',e10.2,'' | '',
     &                     e10.4,'' | '',e10.3,'' | '',f12.4,'' | '',f12.4,'' | UL | '')')
     &                     ra,dec,freq,one,flux,err,mjdstart,mjdend
         ENDIF
      ENDDO 
 99   CONTINUE
      END
