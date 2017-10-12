**==COUNTRATES.FOR
      PROGRAM countrates
c
c    calculates single value or grid/matrix for
c  - count rate to ergs cm2 sec conversion,
c    or
c  - softness or hardness ratio values
c    for a range of spectral parameters,
c    for various satellites, instruments and filters
c
      implicit none
      INTEGER*4  max_sat
      PARAMETER (max_sat=100)
      CHARACTER*80 file_eff_area , output_file , string
      CHARACTER*80 f_eff_area(max_sat)
      CHARACTER*40 satellite(max_sat), instrument(max_sat)
      CHARACTER*20 filter(max_sat)
      CHARACTER*1 yesno
      CHARACTER*2 area
      INTEGER*4 lu_input , ios , k , model , ifear , ifl , itype
      INTEGER*4 itimes , flag , lu_output , nsteps , i , j , flag_cts
      INTEGER*4 flag_single , steps , itime , nch, lu_pf, in, lenact
      INTEGER*4 flag_java, iflag, ii, jj
      REAL*4 crate(10) , nh , emin_area , emax_area , emin , emax
      REAL*4 emin_areas, emax_areas, emin_aream, emax_aream,nufnu
      REAL*4 emin_areah, emax_areah, fekev, conv, effective_area
      REAL*4 energy , soft_band , medium_band , hard_band , increment
      REAL*4 eff_area , anh , alpha , alpha1 , bbreak_energy , redshift
      REAL*4 tt , ak , aa7 , alpha2 , gamm , bk , t , gamma1 , gamma2
      REAL*4 break_energy, alpha_min, alpha_max, delta_alpha, umalpha
      REAL*4 kk(20) , akk(20) , t1 , tt_min , tt_max , delta_tt, ekev
      REAL*4 eemin(max_sat),eemax(max_sat)
      REAL*4 eemin_area(max_sat), eemax_area(max_sat)
      REAL*4 eemin_areas(max_sat), eemax_areas(max_sat)
      REAL*4 eemin_aream(max_sat), eemax_aream(max_sat)
      REAL*4 eemin_areah(max_sat), eemax_areah(max_sat)
      REAL*4 flux_enmin(max_sat), flux_enmax(max_sat)
      REAL*4 counts_enmin(max_sat), counts_enmax(max_sat)
      REAL*4 are , energ

      REAL*4 cnts , errcnts, flussof, errflussof, appo1 , appo2, emad
      REAL*4 eralp
      CHARACTER*80 webprograms
      CHARACTER*80 filename
      CHARACTER*2 detector_id
      LOGICAL ok
      EXTERNAL espec
      EXTERNAL eacma
      COMMON /filt  / energy(5000) , eff_area(5000)
      COMMON /esp   / nh , gamm , bk , ifl , t , itype , gamma1 ,
     &                gamma2 , break_energy
      itime = 0
      ok = .TRUE.
      flag_java=1
c Open configuration file
      lu_pf = 10

c      call getenv('webprograms',webprograms)
      webprograms='.'
      filename = webprograms(1:lenact(webprograms)) //
     &'/countrate/countrates.cf'
      OPEN (lu_pf,FILE=filename,STATUS='old')
      i=0
c read configuration file
      DO WHILE(ok)
         string=' '
         READ (lu_pf,'(a)',end=100) string
         CALL rmvlbk(string)
         in =index(string,' ')
         CALL upc(string(1:in-1))
         IF (string(1:in-1).EQ.'SATELLITE') THEN
            i=i+1
            satellite(i)=string(in+1:lenact(string))
            call rmvlbk(satellite(i))
         ENDIF
         IF (string(1:in-1).EQ.'INSTRUMENT') THEN
            instrument(i)=string(in+1:lenact(string))
            call rmvlbk(instrument(i))
         ENDIF
         IF (string(1:in-1).EQ.'FILE_EFF_AREA') THEN
            f_eff_area(i)=webprograms(1:lenact(webprograms)) //
     &                    string(in+1:lenact(string))
         ENDIF
         IF (string(1:in-1).EQ.'FLUX_ENERGY_RANGE') THEN
            read(string(in+1:lenact(string)),*) eemin(i), eemax(i)
         ENDIF
         IF (string(1:in-1).EQ.'COUNTS_ENERGY_RANGE') THEN
            read(string(in+1:lenact(string)),*)
     &                       eemin_area(i), eemax_area(i)
         ENDIF
         IF (string(1:in-1).EQ.'SOFT_ENERGY_BAND') THEN
            read(string(in+1:lenact(string)),*)
     &                       eemin_areas(i), eemax_areas(i)
         ENDIF
         IF (string(1:in-1).EQ.'MEDIUM_ENERGY_BAND') THEN
            read(string(in+1:lenact(string)),*)
     &                       eemin_aream(i), eemax_aream(i)
         ENDIF
         IF (string(1:in-1).EQ.'HARD_ENERGY_BAND') THEN
            read(string(in+1:lenact(string)),*)
     &                       eemin_areah(i), eemax_areah(i)
         ENDIF
      ENDDO
 100  CONTINUE
      Write (*,*) ' Available satellites/instruments '
      DO ii =1,i
        write (*,'(2x,i2,2x,a,2x,a)') ii,satellite(ii),instrument(ii)
      ENDDO
      write (*,'(''Enter satellite/detector number :'',$)')
      read (*,*) iflag
      file_eff_area=f_eff_area(iflag)
      emin=eemin(iflag)
      emax=eemax(iflag)
      emin_area=eemin_area(iflag)
      emax_area=eemax_area(iflag)
      emin_areas=eemin_areas(iflag)
      emax_areas=eemax_areas(iflag)
      emin_aream=eemin_aream(iflag)
      emax_aream=eemax_aream(iflag)
      emin_areah=eemin_areah(iflag)
      emax_areah=eemax_areah(iflag)
      ekev = 1.0
      string = ' '
      WRITE (*,'('' Energy range for flux (d/f='',2(1x,f5.1),'')'',$)')
     &      emin, emax
      READ (*,'(a)') string
      IF (string.NE.' ') read (string(1:lenact(string)),*) emin, emax
      WRITE (*,'('' Energy for flux density calculation (d/f='',f3.1,
     &      ''keV)'',$)')
     & ekev
      READ (*,'(a)') string
      IF (string.NE.' ') read (string(1:lenact(string)),*) ekev
      lu_input = 11
      PRINT *,file_eff_area
      OPEN (lu_input,FILE=file_eff_area,STATUS='old',ERR=500)
      ok = .TRUE.
      i = 1
      DO WHILE (ok)
         READ (lu_input,*,END=200) energy(i),eff_area(i)
         i = i + 1
      ENDDO
 200  CONTINUE
      write (*,*) ' lines in eff_area ',i-1
      DO j = i , 5000
        energy(j) = energy(i-1)
        eff_area(j) = eff_area(i-1)
      ENDDO
      CLOSE (lu_input)
      CALL frelun(lu_input)
c      do i=1,i-1
c        write (*,*) energy(i),effective_area(energy(i))
c      ENDDO
      flag_single = 1
 300  WRITE (*,'('' 1 for single value 2 for plot file : (d/f=1)'',$)')
      string = ' '
      READ (*,'(a)') string
      IF (string.NE.' ') read (string(1:lenact(string)),*) flag_single
      IF ( flag_single.LT.1 .OR. flag_single.GT.2 ) GOTO 300
      IF ( flag_single.EQ.1 ) THEN
         itimes = 1
 350     IF ( itimes.EQ.1 ) THEN
            WRITE (*,99001)
         ELSE
            WRITE (*,99002)
         ENDIF
         model = 1
         string = ' '
         READ (*,'(a)') string
         IF (string.NE.' ') read (string(1:lenact(string)),*) model
         IF ( model.EQ.0 ) GOTO 99999
         IF ( model.LT.1 .OR. model.GT.7 ) THEN
            WRITE (*,*) '** wrong model type, try again **'
            GOTO 350
         ENDIF
         IF ( model.GE.4 .AND. model.LT.7 ) THEN
            WRITE (*,*) '** model not supported yet **'
            GOTO 350
         ENDIF
         IF ( model.EQ.1 ) THEN
            WRITE (*,'('' enter energy slope :'',$)')
            READ (*,*) alpha
         ELSEIF ( model.EQ.2 .OR. model.EQ.3 ) THEN
            WRITE (*,'('' enter temperature in keV :'',$)')
            READ (*,*) tt
            tt = tt/8.6171E-8
         ELSEIF ( model.EQ.7 ) THEN
            WRITE (*,'('' enter energy slope before break :'',$)')
            READ (*,*) alpha1
            WRITE (*,'('' enter energy slope after break :'',$)')
            READ (*,*) alpha2
            WRITE (*,'('' enter break energy in kev :'',$)')
            READ (*,*) bbreak_energy
            WRITE (*,'('' enter redshift :'',$)')
            READ (*,*) redshift
            bbreak_energy = bbreak_energy/(1.+redshift)
         ENDIF
         WRITE (*,'('' Enter Nh :'',$)')
         READ (*,*) anh
         WRITE (*,99003)
         READ (*,'(a)') yesno
         IF ( yesno.EQ.'e' .OR. yesno.EQ.'E' ) THEN
            ifear = 0
         ELSE
            ifear = 1
         ENDIF
         IF ( alpha.EQ.1 ) alpha = alpha + 0.0001
c
c  do the conversion here
c
         CALL energycr(1.,alpha,tt,anh,0.,model,5,ak,emin,emax,
     &                 emin_area,emax_area,aa7,ifear,alpha1,alpha2,
     &                 bbreak_energy)
c
c write out results
c
         WRITE (*,
     &'('' 1ct/s ('',f5.2,  ''-'',f5.2,'' keV)= '',
     & 1pg9.3,0p,'' erg cm-2 s-1'',2x,''('',f5.2,  ''-'',
     &f5.2,'' keV)'')') emin_area, emax_area, ak , emin , emax
         umalpha=1.-alpha
         if (umalpha.eq.0.) then
            conv=ekev**(-alpha)*1./log(emax/emin)/(ekev*2.418E-12)
         else
            conv=umalpha*ekev**(-alpha)/(emax**umalpha-emin**umalpha)/
     &                                               (ekev*2.418E-12)
         endif
         fekev=ak*conv
         nufnu = fekev*ekev*ekev*2.418e-12
         WRITE (*,'("fx(",f4.2,"keV) :",f6.3," microJy")') ekev, fekev
         WRITE (*,'("nuFnu((",f4.2,"keV) :",1pe12.4," erg/cm2/s")') ekev, nufnu
         GOTO 350
      ELSE
 400          WRITE (*,
     &'('' 1 for c/r ct-1, 2 for softness ratio '',                 '' 3
     & for hardn ratio on y axis '',/,           '' 4 for softness matri
     &x, 5 for hardness matrix''         '' 6 for flux matrix, 7 for sof
     &t-hard band matrix '',$)')
            READ (*,*) flag_cts
c            IF ( flag_cts .EQ .7 ) THEN
c              write (*,*) ' Output is for H1 in RASS !! '
c            ENDIF
            IF ( flag_cts.LT.1 .OR. flag_cts.GT.7 ) THEN
               WRITE (*,'('' wrong choice '')')
               GOTO 400
            ENDIF
         WRITE (*,'('' Output file :'',$)')
         READ (*,'(a)') output_file
         CALL getlun(lu_output)
         OPEN (lu_output,FILE=output_file,STATUS='unknown')
         WRITE (*,99001)
         model = 1
         string = ' '
         READ (*,'(a)') string
         IF (string.NE.' ') read (string(1:lenact(string)),*) model
c         READ (*,*) model
         IF ( flag_cts.LT.2 .OR. flag_cts.GT.5 ) THEN
            WRITE (*,99003)
            READ (*,'(a)') yesno
            IF ( yesno.EQ.'e' .OR. yesno.EQ.'E' ) THEN
               ifear = 0
            ELSE
               ifear = 1
            ENDIF
         ELSE
            ifear = 1
         ENDIF
c         nsteps = 31
         nsteps = 41
         IF ( model.EQ.1 ) THEN
            alpha_min = -1.1
            alpha_max = 3.0
            delta_alpha = (alpha_max-alpha_min)/float(nsteps)
            alpha = alpha_min - delta_alpha
         ELSEIF ( model.EQ.2 ) THEN
            tt_min = 0.010
            tt_max = 3.
            delta_tt = (tt_max/tt_min)**(1./float(nsteps))
            tt = tt_min/delta_tt
         ENDIF
         DO 450 i = 1 , nsteps + 1
            IF ( mod(i,2).EQ.0 ) WRITE (*,'(''+ '',I4)') i
            IF ( model.EQ.1 ) THEN
               alpha = alpha + delta_alpha
            ELSEIF ( model.EQ.2 ) THEN
               tt = tt*delta_tt
               t1 = tt/8.6171E-8
            ENDIF
            IF ( flag_cts.LE.3 ) THEN
               anh = 5.E19
               steps = 20.
               increment = 1000**(1./steps)
            ELSEIF ( flag_cts.GE.4 ) THEN
               steps = 20.
               IF ( model.EQ.1 ) THEN
                  anh = 2.E19
                  increment = 3000.**(1./steps)
               ELSEIF ( model.EQ.2 ) THEN
                  anh = 5.E18
                  increment = 200.**(1./steps)
               ENDIF
            ENDIF
            DO 420 j = 1 , steps
               anh = anh*increment
               kk(j) = anh
               IF ( flag_cts.EQ.1 .OR. flag_cts.EQ.6 ) THEN
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_area,emax_area,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  akk(j) = ak
               ELSEIF ( flag_cts.EQ.2 .OR. flag_cts.EQ.4 ) THEN
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_areas,emax_areas,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  soft_band = aa7
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_aream,emax_aream,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  medium_band = aa7
                  akk(j) = soft_band/medium_band
               ELSEIF ( flag_cts.EQ.3 .OR. flag_cts.EQ.5 ) THEN
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_areah,emax_areah,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  hard_band = aa7
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_aream,emax_aream,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  medium_band = aa7
                  akk(j) = hard_band/medium_band
               ELSEIF ( flag_cts.EQ.7 ) THEN
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_areah,emax_areah,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  hard_band = aa7
                  CALL energycr(1.,alpha,t1,anh,0.,model,5,ak,emin,emax,
     &                          emin_areas,emax_areas,aa7,ifear,alpha1,
     &                          alpha2,bbreak_energy)
                  soft_band = aa7
c                  akk(j) = ( hard_band-soft_band )/
c     &                     ( soft_band+hard_band )
                  akk(j) = hard_band/soft_band
               ENDIF
 420        CONTINUE
            itime = itime + 1
            IF ( itime.EQ.1 ) THEN
               IF ( flag_java .EQ. 1) THEN
c                  WRITE (lu_output,'(''this[0] = new lineSR'')')
c                  WRITE (lu_output,'(''( 0 '',20('','',1pe10.3),'')'')')
                  WRITE (lu_output,'(''!'',20(1pe10.3))')
     &                 (kk(j),j=1,steps)
               ELSE
                  WRITE (lu_output,'(''!'',3x,20(2x,1pe10.3))')
c                  WRITE (lu_output,'(20(2x,1pe10.3))')
     &                 (kk(j),j=1,steps)
               WRITE (lu_output,'(''!'')')
               ENDIF
            ELSE IF ( model.EQ.1 ) THEN
               IF ( flag_java .EQ. 1) THEN
                  IF (itime.le.10) THEN
c                    WRITE (lu_output,
c     &           '(''this['',i1,''] = new lineSR'')') itime-1
                  ELSE IF (itime.le.100) THEN
c                    WRITE (lu_output,
c     &           '(''this['',i2,''] = new lineSR'')') itime-1
                  ENDIF
                  WRITE (lu_output,
c     &            '(''( '',f4.1,12('','',1pe10.3),'')'')')
     &            '(f4.1,20(1pe10.3))')
     &            alpha, (akk(j),j=1,steps)
               ELSE
                  WRITE (lu_output,'(1x,f4.1,20(2x,1g10.3))')
     &            alpha, (akk(j),j=1,steps)
               ENDIF
            ELSE IF ( model.EQ.2 ) THEN
              DO j = 1, steps
               WRITE (lu_output,'(1x,f5.3,20(2x,1pe10.3))')
     &          tt, (akk(jj),jj=1,steps)
              END DO
            ENDIF
 450     CONTINUE
         CLOSE (lu_output)
         GOTO 99999
      ENDIF
c
c  error conditions
c
 500  WRITE (*,99004)
99001 FORMAT (/,' Model type',/,'   1 -> power law',/,
     &        '   2 -> black body',/,'   3 -> thermal bremsstrahlung',/,
     &        '   7 -> double power law     (d/f=1) : ',$)
99002 FORMAT (/,' Model type',/,'   1 -> power law',/,
     &        '   2 -> black body',/,'   3 -> thermal bremsstrahlung',/,
     &        '   7 -> double power law        ',/,'   0 -> stop : ',$)
99003 FORMAT (/,' Emitted/Observed flux d/f=observed flux) : ',$)
99004 FORMAT (/,T5,' >>> ERROR: cannot open input file',/)
99999 END


      SUBROUTINE energycr(crate,ggamm,tt,nhydr,hys,iifl,iitype,
     &                 flxog,emin_flux,emax_flux,emin_area,emax_area,
     &                 aa8,ifear,ggamma1,ggamma2,bbreak_energy)
C
C  this subroutine converts count rates into fluxes
C
C  crate - source count rate -
C
C  ggamm - power law energy slope -
C
C  tt    - temperature in kelvin degrees -
C
C  nhydr - hydrogen column density in our galaxy  (real*4) -
C
C  hys   - intrinsic absorption  (real*4) -
C
C  iifl  - flag for spectral type     ifl = 1  :  power law
C                                     ifl = 2  :  black body
C                                     ifl = 3  :  thermal brems
C                                     ifl = 4  :  exponential
C                                     ifl = 7  :  double power law
C
C  iitype- flag for absorption model  itype = 0 : brown & gould
C                                     itype = 1 : gas model
C                                     itype = 2 : 0.15 micron model
C                                     itype = 3 : 0.60 micron model
C                                     itype = 4 : brown & gould (xuv ext
C                                     itype = 5 : morrison & mccammon
C
C  flxog - source flux outside the galaxy ( on source side of galaxy)
C
C  emin_flux, emax_flux lower and upper boundary of energy band where flux is
C             calculated
C
C  ifear = 1 for fluxes at the earth
C  ifear = 0 for fluxes corrected for galactic absorption
C
c
c  emin_area minumum value of energy in effective area table
c  emax_area maximum value of energy in effective area table
c
      EXTERNAL espec
      EXTERNAL eacma
      integer*4 ifl, iifl, itype, nmax, ifear, n4, n7
      integer*4 iitype
      REAL*4 nhydr, nh, t, tt, gamm, ggamm, gamma1, ggamma1, gamma2
      real*4 ggamma2, break_energy, bk, hys , aa4, aa8, ra48
      real*4 emin_flux, emax_flux, emin_area, emax_area, flxog, crate
      real*4 bbreak_energy
      COMMON /esp   / nh, gamm, bk, ifl, t, itype, gamma1,
     &                gamma2, break_energy
      ifl = iifl
      t = tt
      itype = iitype
      gamm = ggamm
      gamma1 = ggamma1
      gamma2 = ggamma2
      break_energy = bbreak_energy
      nmax = 200
      bk = 8.6171E-8
      IF ( ifear.EQ.1 ) THEN
          nh = (nhydr+hys)*1.E-22
      ELSE
          nh = hys*1.E-22
      END IF
      CALL stup1(espec,emin_flux,emax_flux,aa4,nmax)
      nh = (nhydr+hys)*1.E-22
      gamm = gamm + 1.
      gamma1 = gamma1 + 1.
      gamma2 = gamma2 + 1.
      CALL stup1(eacma,emin_area,emax_area,aa8,nmax)
      gamm = gamm - 1.
      gamma1 = gamma1 - 1.
      gamma2 = gamma2 - 1.
      ra48 = aa4/aa8*1.602192E-9
      flxog = ra48*crate
      RETURN
      END

**==eacma.f
      FUNCTION eacma(ener)
      integer*4 itype, ifl
      REAL*4 nh, absor , ener, atten, effa, gamm, eacma, es, bk, t
      real*4 emean, sigma, break_energy, gamma1, gamma2, effective_area
      COMMON /esp   / nh, gamm, bk, ifl, t, itype,
     &                gamma1, gamma2, break_energy
      absor = atten(ener,nh,itype,1.,1.)
      effa = effective_area(ener)
      IF ( ifl.EQ.1 ) THEN
         IF ( gamm.LE.-20. ) THEN
            eacma = absor*ener**20*effa
            RETURN
         END IF
         IF ( gamm.GT.20 ) THEN
            eacma = 0.
            RETURN
         END IF
         eacma = absor*ener**(-gamm)*effa
         RETURN
      ELSE IF ( ifl.EQ.2 ) THEN
         es = ener/(bk*t)
         IF ( es.GT.60. ) THEN
            eacma = absor*effa*exp(2.*alog(ener)-es)
            RETURN
         END IF
         eacma = absor*effa*ener*ener/(exp(es)-1.)
         RETURN
      ELSE IF ( ifl.EQ.3 ) THEN
         es = ener/(bk*t)
         eacma = absor*effa*exp(-.4*alog(es)-alog(ener)-es)
         RETURN
      ELSE IF ( ifl.EQ.4 ) THEN
         es = ener/(bk*t)
         eacma = absor*effa*exp(-es)
         RETURN
      ELSE IF ( ifl.EQ.5 ) THEN
         emean = gamm
         sigma = 3.E-4*emean
         es = (ener-emean)*(ener-emean)/(2.*sigma*sigma)
         IF ( es.GE.88 ) THEN
            eacma = 0.
            RETURN
         ELSE
            eacma = absor*effa/sigma*exp(-es)
            RETURN
         END IF
      ELSE IF ( ifl.EQ.6 ) THEN
         es = ener/bk/t
         eacma = absor*effa*ener**2.12*exp(-es)
         RETURN
      ELSE IF ( ifl.EQ.7 ) THEN
         IF ( ener.LT.break_energy ) THEN
            eacma = absor*ener**(-gamma1)*effa
         ELSE
            eacma = absor*ener**(-gamma2)
     &              *effa*break_energy**(gamma2-gamma1)
         END IF
         RETURN
      END IF
      END

**==STUP1.FOR
      SUBROUTINE stup1(func,xmin,xmax,result,nloops)
c
C ** this rutine calculates definite integrals of the function "func"
C ** in the interval xmin-xmax using the stupid trapezoidal rule.
C ** the only difference between this and other "smarter" routines
C ** is that this one always works while others too often don't!
c
      INTEGER*4 nloops , i , last
      REAL*4 aloo , h , xmax , xmin , first , func , result , xw
      REAL*4 fi , xl
      aloo = nloops - 1
      h = (xmax-xmin)/aloo
      first = func(xmin)/2.
      result = first
      xw = xmin
c
      DO 100 i = 1 , nloops - 2
         xw = xw + h
         fi = func(xw)
         result = result + fi
 100  CONTINUE
c
      xl = xw + h
      last = func(xl)/2.
      result = (result+last)*h
      RETURN
      END


**==ATTEN.FOR
      FUNCTION atten(e,enx,itype,raox,rafe)
c
c  interstellar absorption
c
      INTEGER*4 itype
      REAL*4 ax , enx , e , raox , rafe , axs , atten
      ax = -enx*axs(e,itype,raox,rafe)
      IF ( ax.GE.0 ) THEN
         atten = 1.
         RETURN
      ELSEIF ( ax.GT.-40. ) THEN
         atten = exp(ax)
         RETURN
      ELSE
         atten = 0.
         RETURN
      ENDIF
      END


**==EFFECTIVE_AREA.FOR
      FUNCTION effective_area(e)
c
C   this function returns the effective area at a given energy e
c
      INTEGER*4 j , k , kk
      REAL*4 r , effective_area, e,energy, area
      COMMON /filt  / energy(5000) , area(5000)
      j=1
      DO WHILE ( e.GE.energy(j) )
         k = j
         j=j+1
      ENDDO
      kk = k - 1
      IF ( kk.LE.0 ) THEN
         k = k + 1
         kk = kk + 1
      ENDIF
      r = alog(area(kk)/area(k))/alog(energy(kk)/energy(k))
c      effective_area = area(k)*((e/energy(k))**r)
      effective_area = area(k)
      RETURN
      END

**==AXS.FOR
C=============================================================================
C modified mssl interstellar absorption package  (rjb+pg)
C with addition adapted from new
C
      FUNCTION axs(e,itype,raox,rafe)
C ism cross section
C this function calculates interstellar attenuation coefficients
C itype=0     brown & gould model
C itype=1     fireman gas model
C itype=2     fireman 0.15 micr model
C itype=3     fireman 0.60 micr model
C itype=4     brown & gould (extended to xuv) (likely cruddace)
C itype=5     morrison and mccammon (adapted from new)
C raox is the abundance of oxygen required rel to 'cosmic'
C rafe is the abundance of iron required rel to 'cosmic'
C mods to be made ... correct edge energies .....
C  ni  8.33165
C  fe  7.1112
C  cr  5.9892
C  ca  4.0381
C  a   3.2029
C  s   2.47048
C  si  1.8400
C  mg  1.30339
C  ne  0.866889
C  o   0.5317
C  n   0.4000
C  c   0.28384
C  he  0.0243
C  h   0.0136
      INTEGER*4 j1 , itype , j , k , kk , i
      REAL*4 e , ex , r , xs , sig , axs , raox , oxy , eng , absr2 ,
     &       coef , e1 , xd
      REAL*4 sg , dex , rafe , fe , fct
      DIMENSION ex(40) , sig(40) , e1(22) , sg(22,3)
      DIMENSION coef(15,3) , eng(16)
      DATA ex/.0136 , .0177 , .02 , .0243 , .0243 , .03 , .035 , .045 ,
     &     .07 , .1 , .2 , .2838 , .2838 , .4016 , .4016 , .5320 ,
     &     .5320 , .8669 , .8669 , 1.3050 , 1.3050 , 1.8389 , 1.8389 ,
     &     2.4720 , 2.4720 , 3.2029 , 3.2029 , 4. , 4. , 5. , 5. , 6. ,
     &     6. , 7. , 7. , 8. , 8. , 9. , 10. , 12./
                                   !mmcc
      DATA sig/.15 , .172 , .175 , .17 , .25 , .32 , .35 , .41 , .51 ,
     &     .58 , .63 , .60 , .70 , .67 , .75 , .74 , 1.63 , 1.72 ,
     &     2.01 , 2.16 , 2.28 , 2.4 , 2.74 , 2.89 , 3.3 , 3.45 , 3.71 ,
     &     3.86 , 3.86 , 3.92 , 3.92 , 3.95 , 3.95 , 3.95 , 3.95 ,
     &     3.94 , 3.94 , 3.92 , 3.90 , 3.90/
      DATA e1/.3 , .5320 , .5320 , .8669 , .8669 , 1.3050 , 1.3050 ,
     &     1.8389 , 1.8389 , 2.4720 , 2.4720 , 3.2029 , 3.2029 ,
     &     4.0381 , 4.0381 , 5.9892 , 5.9892 , 7.1120 , 7.1120 ,
     &     8.3328 , 8.3328 , 10./
      DATA sg/0.8 , 0.9 , 1.9 , 2.0 , 2.4 , 2.6 , 2.8 , 2.9 , 3.2 ,
     &     3.5 , 3.9 , 4.1 , 4.3 , 4.6 , 4.7 , 5.0 , 5.1 , 5.3 , 10.6 ,
     &     11.2 , 11.8 , 12.3 , 0.7 , 0.9 , 1.4 , 1.7 , 2.0 , 2.4 ,
     &     2.6 , 2.8 , 3.0 , 3.4 , 3.9 , 4.1 , 4.3 , 4.6 , 4.7 , 5.0 ,
     &     5.1 , 5.3 , 10.6 , 11.2 , 11.8 , 12.3 , 0.6 , 0.7 , 0.8 ,
     &     1.1 , 1.5 , 1.9 , 2.1 , 2.4 , 2.7 , 3.3 , 3.9 , 4.1 , 4.3 ,
     &     4.6 , 4.7 , 5.0 , 5.1 , 5.3 , 10.6 , 11.2 , 11.8 , 12.3/
      DATA coef/17.3 , 34.6 , 78.1 , 71.4 , 95.5 , 308.9 , 120.6 ,
     &     141.3 , 202.7 , 342.7 , 352.2 , 433.9 , 629.0 , 701.2 ,
     &     953.0 , 608.1 , 267.9 , 18.8 , 66.8 , 145.8 , -380.6 ,
     &     169.3 , 146.8 , 104.7 , 18.7 , 18.7 , -2.4 , 30.9 , 25.2 ,
     &     0.0 , -2150. , -476.1 , 4.3 , -51.4 , -61.1 , 294.0 , -47.7 ,
     &     -31.5 , -17.0 , 0.0 , 0.0 , 0.75 , 0.0 , 0.0 , 0.0/
      DATA eng/0.03 , 0.1 , 0.284 , 0.4 , 0.532 , 0.707 , 0.867 ,
     &     1.303 , 1.84 , 2.471 , 3.21 , 4.038 , 7.111 , 8.331 , 10.0 ,
     &     100.0/
      j1 = 9
      IF ( itype.EQ.0 .OR. itype.EQ.4 ) THEN
C
C.....brown and gould ( 0.0136 or 0.07 to 12 kev) ... only o supported........
C
         IF ( itype.EQ.4 ) j1 = 1
         DO 50 j = j1 , 40
            k = j
            IF ( e.LE.ex(j) ) GOTO 100
 50      CONTINUE
 100     kk = k - 1
         IF ( kk.LE.0 ) THEN
            k = k + 1
            kk = kk + 1
         ENDIF
         r = (e-ex(kk))/(ex(k)-ex(kk))
         xs = r*(sig(k)-sig(kk)) + sig(kk)
         xs = xs/e/e/e
         xs = xs
         axs = xs + 1.082*(raox-1.)*oxy(e)
         RETURN
      ELSEIF ( itype.EQ.5 ) THEN
C
C.....morrison and mc cammon ( 0.03-100 kev) ... no o and fe supported........
C     in units of 10**22
C     also added in is thomson xsection
C
         DO 150 i = 1 , 16
            IF ( e.LT.eng(i) ) GOTO 200
 150     CONTINUE
 200     i = i - 1
         IF ( i.EQ.0 ) i = 1
         absr2 = (coef(i,1)+coef(i,2)*e+coef(i,3)*e*e)/e**3
                      !protection added by lc (le range)
         axs = absr2*0.01 + 0.0067
         RETURN
      ELSE
C
C.....fireman ( 0.3-10 kev ) ... o and fe supported ..........................
C
         DO 250 j = 1 , 22
            k = j
            IF ( e.LE.e1(j) ) GOTO 300
 250     CONTINUE
 300     kk = k - 1
         IF ( kk.LE.0 ) THEN
            k = k + 1
            kk = kk + 1
         ENDIF
         r = (e-e1(kk))/(e1(k)-e1(kk))
         xd = r*(sg(k,itype)-sg(kk,itype)) + sg(kk,itype)
         xd = xd/e/e/e
         xd = xd
         dex = 1.022*(rafe-1.)*fe(e)
         axs = xd + 1.216*(raox-1.)*oxy(e)*fct(e,itype) + dex
         RETURN
      ENDIF
      END

**==OXY.FOR
      FUNCTION oxy(e)
c
c  oxygen
c
      integer*4 j,k,kk
      real*4 eox(8), sox(8), r, e , oxy
      DATA sox, eox/1.79, 2.74, 3.30, 85.53, 104.36, 123.76, 144.71,
     &     155.37, 0.10, 0.30, 0.5320, 0.5320, 1., 2., 5., 10./
      DO j = 1, 8
         k = j
         IF ( e.LE.eox(j) ) GO TO 100
      END DO
 100  CONTINUE
      kk = k - 1
      IF ( kk.LE.0 ) THEN
         k = k + 1
         kk = kk + 1
      END IF
      r = (e-eox(kk))/(eox(k)-eox(kk))
      oxy = r*(sox(k)-sox(kk)) + sox(kk)
      oxy = oxy/e/e/e
      oxy = oxy*1.E-2
      RETURN
      END


**==FE.FOR
      FUNCTION fe(e)
c
c  iron
c
      integer*4 j,k,kk
      real*4 efe(12), sfe(12), e, fe, r
      DATA sfe, efe/2.15, 7.74, 23.9, 34.9, 50.6, 59.7, 69.7, 74.5,
     &     593., 626.9, 686.1, 772.5, .3, .6, 1., 1.5, 2.4, 3.5, 5.0,
     &     7.112, 7.112, 8., 10., 15./
      IF ( e.LE..2 ) THEN
         fe = 0.
         RETURN
      ELSE
         DO j = 1, 12
            k = j
            IF ( e.LE.efe(j) ) GO TO 50
         END DO
 50      CONTINUE
         kk = k - 1
         IF ( kk.LE.0 ) THEN
            k = k + 1
            kk = kk + 1
         END IF
         r = (e-efe(kk))/(efe(k)-efe(kk))
         fe = r*(sfe(k)-sfe(kk)) + sfe(kk)
         fe = fe/e/e/e
         fe = fe*1.E-2
         RETURN
      END IF
      END

**==FCT.FOR
      FUNCTION fct(e,itype)
c
c  auxiliary ism routine
c
      integer*4 j,k,kk,itype
      real*4 eq(7), f(7,3) , e , r , fct
      DATA f/7*1., .155, .70, .86, .93, .98, 1., 1., .187, .317, .587,
     &     .77, .93, 1., 1./
      DATA eq/.3, .6, 1., 1.5, 2.4, 3., 4./
      DO j = 1, 7
         k = j
         IF ( e.LE.eq(j) ) GO TO 100
      END DO
 100  CONTINUE
      kk = k - 1
      IF ( kk.LE.0 ) THEN
         k = k + 1
         kk = kk + 1
      END IF
      r = (e-eq(kk))/(eq(k)-eq(kk))
      fct = r*(f(k,itype)-f(kk,itype)) + f(kk,itype)
      IF ( fct.LT.0. ) fct = 0.
      RETURN
      END

**==ESPEC.FOR
      FUNCTION espec(ener)
      INTEGER*4 itype , ifl
      REAL*4 nh , absor , ener , atten , espec , gamm , es , bk , t ,
     &       emean
      REAL*4 sigma , break_energy , gamma1 , gamma2
      COMMON /esp   / nh , gamm , bk , ifl , t , itype , gamma1 ,
     &                gamma2 , break_energy
      absor = atten(ener,nh,itype,1.,1.)
      IF ( ifl.EQ.1 ) THEN
         espec = absor*ener**(-gamm)
         RETURN
      ELSEIF ( ifl.EQ.2 ) THEN
         es = ener/(bk*t)
         IF ( es.GT.60. ) THEN
            espec = absor*exp(3*alog(ener)-es)
            RETURN
         ENDIF
         espec = absor*ener*ener*ener/(exp(es)-1.)
         RETURN
      ELSEIF ( ifl.EQ.3 ) THEN
         es = ener/(bk*t)
         espec = absor*exp(-.4*alog(es)-es)
         RETURN
      ELSEIF ( ifl.EQ.4 ) THEN
         es = ener/(bk*t)
         espec = absor*ener*exp(-es)
         RETURN
      ELSEIF ( ifl.EQ.5 ) THEN
         emean = gamm
         sigma = 3.E-4*emean
         es = (ener-emean)*(ener-emean)/(2.*sigma*sigma)
         IF ( es.GE.88 ) THEN
            espec = 0.
            RETURN
         ELSE
            espec = absor*ener/sigma*exp(-es)
            RETURN
         ENDIF
      ELSEIF ( ifl.EQ.6 ) THEN
         es = ener/(bk*t)
         IF ( es.GT.60 ) THEN
            espec = ener**3.12
         ELSE
            espec = absor*ener**3.12*exp(-es)
         ENDIF
         RETURN
      ELSEIF ( ifl.EQ.7 ) THEN
         IF ( ener.LT.break_energy ) THEN
            espec = absor*ener**(-gamma1)
         ELSE
            espec = absor*ener**(-gamma2)*break_energy**(gamma2-gamma1)
         ENDIF
         RETURN
      ELSE
         WRITE (*,'('' sub ESPEC called with a wrong flag '')')
         RETURN
      ENDIF
      END
