      PROGRAM dbxrtcat
c
c calculates derived quantitites and writes them to XRTCAT database 
c
      IMPLICIT NONE
      INTEGER*4 total_db , i , ierr , rah , ram , dd , dm , lu_input
      INTEGER*4 no_of_entries , nrec , maxl , ids , j, class, imsol
      INTEGER*4 lu_skycov, cov_total, no_in_sample, ndistinct, iji
      INTEGER*4 iaddr,type,irasec,idsec
      REAL*4 radian, dist, angle,xp,yp,xp_center,yp_center,rasec,dsec
      REAL*4 sh,sh_error,alpha_sh,nh_21cm,sh_plus,sh_minus,fluxcts_210
      REAL*4 alpha_sh_plus,alpha_sh_minus,aerrplus_s,aerrminus_s
      REAL*4 count_rate_full,fluxcts_052,cr_soft,cr_hard,count_rate
      REAL*4 fluxcts_0124,cr_soft_limit,cr_hard_limit
      REAL*4 exposure, flag_survey
      REAL*8 temp , ra_counterpart, dec_counterpart, ra, dec
      CHARACTER*1 update_alphas, dummy
      CHARACTER*10 sample_name , index_name
      CHARACTER*21 swift_name
      CHARACTER*30 database_name, metabase, table
      CHARACTER*60 pname , input_file
      CHARACTER*80 version, char_string, file_rec
      CHARACTER*160 string
      LOGICAL*4 fortran , write , ok 
      INCLUDE '/Users/giommi/app/simulate_survey_fits/include/browse.inc'
      INCLUDE '/Users/giommi/app/simulate_survey_fits/include/xdb.inc'
      INCLUDE '/Users/giommi/app/simulate_survey_fits/include/io.inc'
      INCLUDE '/Users/giommi/app/usitedef.inc'
      DATA version/'DBXRTCAT 1.0'/
      DATA file_rec/'/dbase/manager/utilities/db_pop/db_pop_rec'/
        
      radian = 57.29578
      xp_center=500.
      yp_center=500.
c
c Browse initialization
c
      total_db = 0
      metabase = 'ZZDB'
      CALL START_UP_2(version,file_rec)
      CALL BROWSE_START(ierr)
      CALL XDB_INFO(metabase,total_db,ierr)
      IF ( ierr.NE.0 ) WRITE (*,99001)
      WRITE (*,'(''  Enter database name (e.g. XRTCAT ) : '')')
c
c   get database name
c
      database_name = ' '
      table = ' '
      write = .TRUE.
      CALL FIND_DATABASE(database_name,table,ierr)
      IF ( ierr.NE.0 ) CALL exit
c open it
      CALL database_begin(database_name,write,no_of_entries,maxl,ierr)
      Sample_name=' '
      CALL FIND_SAMPLE(Database_name,Sample_name,Zcurrent_sample_name,
     &                 Ierr)
      IF ( ierr.NE.0 ) RETURN
      CALL sample_check(sample_name,database_name,ierr)
      Index_name='DEC'
      CALL FIND_INDEX(Database_name,Sample_name,Index_name,
     &                Zcurrent_index_name,Ierr)
      CALL INDEX_CHECK(Index_name,Sample_name,Database_name,Ierr)
      CALL index_begin(database_name,sample_name,index_name,
     &                 no_in_sample,ndistinct,type,iaddr,ierr)
      WRITE (*,'('' Processing '',I8,'' entries  '')') no_in_sample 
      nrec = no_of_entries + 1
      swift_name(1:6)='SWIFTJ'
      DO 100 i = 2 , no_in_sample + 1
         IF ( index_name.EQ.' ' ) THEN
            iji = i
         ELSE
            CALL index_value(database_name,sample_name,index_name,i,iji,
     &                       ierr)
         ENDIF
         CALL read_buffer(database_name,iji,ierr)
         CALL xclock (i,no_in_sample,1)
         pname = 'RA'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         ra = temp 
         pname = 'DEC'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         dec = temp 
         CALL prec(ra,dec,2000,2)
         CALL chra(ra,rah,ram,rasec,1)
         CALL chdec(dec,dd,dm,dsec,1)
         pname = 'EXPOSURE'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         exposure=temp
         pname = 'SH'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         sh = temp 
         pname = 'SH ERROR'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         sh_error = temp 
         pname = 'NH_21cm'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         nh_21cm = temp 
         pname = 'COUNT_RATE_SOFT'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         cr_soft = temp 
         IF ( exposure .LT. 3.e4 ) THEN 
            cr_soft_limit = 10.**(-log10(exposure)+0.924)
         ELSE 
            cr_soft_limit = 10.**(-0.5*log10(exposure) - 1.187)
         ENDIF
         pname = 'COUNT_RATE_HARD'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         cr_hard = temp 
         IF ( exposure .LT. 3.e4 ) THEN 
            cr_hard_limit = 10.**(-log10(exposure) + 0.924)
         ELSE 
            cr_hard_limit = 10.**(-0.5*log10(exposure) - 1.187)
         ENDIF
         pname = 'COUNT_RATE_FULL'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         count_rate_full = temp 
         IF ( count_rate_full .NE. 0.) THEN
            count_rate=count_rate_full
         ELSE
            count_rate = cr_soft + cr_hard
         ENDIF
         IF ( exposure .LT. 60000. ) THEN 
             IF (count_rate*exposure .GE. 12. ) THEN 
                flag_survey = 1
             ELSE
                flag_survey = 0
             ENDIF 
         ELSE
             IF ( count_rate*sqrt(exposure) .GT. 0.05 ) THEN
               flag_survey = 1    
             ELSE
               flag_survey = 0
             ENDIF
         ENDIF
         pname = 'FLUX_LIM_FLAG'
         temp = flag_survey
         CALL val_par (database_name,pname,temp,char_string,ierr)
         IF ( sh.NE.99.0) THEN 
            call xrt_softconvert(sh,nh_21cm,alpha_sh)
            sh_plus=sh+sh_error
            sh_minus=sh-sh_error
            call xrt_softconvert(sh_plus,nh_21cm,alpha_sh_plus)
            call xrt_softconvert(sh_minus,nh_21cm,alpha_sh_minus)
            IF ( alpha_sh_plus .NE. -99. ) THEN
              aerrplus_s = alpha_sh_plus - alpha_sh
           ELSE
              aerrplus_s = -99.
           ENDIF
           IF ( alpha_sh_minus .NE. -99. ) THEN
              aerrminus_s = alpha_sh - alpha_sh_minus
           ELSE
              aerrminus_s = -99.
           ENDIF
c            if ( aerrplus_s .LT. 0.2 ) then 
c              write (*,*) ' nh, sh, alpha, error_plus,erro_minus ', 
c     &                    nh_21cm,sh,alpha_sh,aerrplus_s,aerrminus_s
c            ENDIF
         ELSE
            alpha_sh=99.0
         endif
         pname = 'ALPHA_SH'
         temp=alpha_sh
         CALL val_par (database_name,pname,temp,char_string,ierr)
         pname = 'ALPHA_SH ERROR'
         IF ( ( abs(aerrplus_s) .GT. 90. ) .OR. 
     &        ( abs(aerrminus_s) .GT. 90. ) .OR. 
     &        ( abs(alpha_sh) .GT. 90. ) ) THEN 
           temp = 0.
         ELSE
           temp= (aerrplus_s+aerrminus_s)/2.
         ENDIF
         CALL val_par (database_name,pname,temp,char_string,ierr)
         IF ( count_rate .NE. 0.0) THEN
            call cts_flux052(alpha_sh,nh_21cm,fluxcts_052)
            call cts_flux0124(alpha_sh,nh_21cm,fluxcts_0124)
            call cts_flux210(alpha_sh,nh_21cm,fluxcts_210)
         ELSE 
            fluxcts_052 = 0.  
            fluxcts_0124 = 0.  
            fluxcts_210 = 0.  
         ENDIF
         pname = 'FLUX052'
         temp = count_rate*fluxcts_052
         CALL val_par (database_name,pname,temp,char_string,ierr)
         pname = 'FLUX0124'
         temp = count_rate*fluxcts_0124
         CALL val_par (database_name,pname,temp,char_string,ierr)
         pname = 'FLUX210'
         temp = count_rate*fluxcts_210
         CALL val_par (database_name,pname,temp,char_string,ierr)
         write(swift_name(7:8),'(i2.2)') rah
         write(swift_name(9:10),'(i2.2)') ram
         irasec=rasec
         write(swift_name(11:12),'(i2.2)') irasec
         swift_name(13:13)='.'
         write(swift_name(14:14),'(i1.1)') int((rasec-irasec)*10.)
         if (dec.ge.0) then 
             swift_name(15:15)='+'
         ELSE
             swift_name(15:15)='-'
         ENDIF
         write(swift_name(16:17),'(i2.2)') abs(dd)
         write(swift_name(18:19),'(i2.2)') abs(dm)
         idsec=dsec
         write(swift_name(20:21),'(i2.2)') idsec
         pname = 'NAME'
         char_string=swift_name 
c         write (*,'(a)') swift_name
         CALL val_par (database_name,pname,temp,char_string,ierr)
         pname = 'X_PIXEL'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         xp = temp 
         pname = 'Y_PIXEL'
         temp=0.
         CALL par_val(database_name,pname,temp,char_string,ierr)
         yp = temp
         dist=sqrt((xp - xp_center)**2+
     &              (yp-yp_center)**2)*2.36/60.
         pname = 'OFF_AXIS_ANGLE'
         temp=dist
         CALL val_par (database_name,pname,temp,char_string,ierr)
         pname = 'OTHER_NAME'
         char_string= ' '
         CALL val_par (database_name,pname,temp,char_string,ierr)
         CALL write_buffer(database_name,iji,ierr)
  100 continue
99001 FORMAT (' Error opening defaults file')
      END
**==xrt_SOFTCONVERT.FOR

      SUBROUTINE xrt_softconvert(softness,nh,alpha)
      INTEGER*4 i , j , k , lu_input , igood , itime
      REAL*4 nh , alpha , softness , test , testmin , offset
      REAL*4 en(41) , nhvalue(20) , srgood(41)
      REAL*4 sratio(41,20)
      CHARACTER*2 detector_id
      CHARACTER*80 file_matrix
      LOGICAL ok
      if (nh.eq.-99.) then
        alpha=-99.
        return
      endif
      itime = itime + 1
      IF ( itime.EQ.1 ) THEN
         CALL getlun(lu_input)
            file_matrix=
     &       '/Users/giommi/app/load/xrtcat/xrt_soft_03_30_20_100.dat'
         OPEN (lu_input,FILE=file_matrix,STATUS='old')
         READ (lu_input,*,END=100) (nhvalue(j),j=1,20)
         i = 0
         ok = .TRUE.
         DO 50 WHILE (ok)
            i = i + 1
            READ (lu_input,*,END=100) en(i) , (sratio(i,j),j=1,20)
 50      CONTINUE
 100     CLOSE (lu_input)
         CALL frelun(lu_input)
      ENDIF
      k = 1
      DO 600 WHILE (nh.GE.nhvalue(k).and.k.lt.20)
         k = k + 1
 600  CONTINUE
      DO 700 i = 1 , 41
         srgood(i) = (sratio(i,k)-sratio(i,k-1))
     &               /(nhvalue(k)-nhvalue(k-1))*(nh-nhvalue(k-1))
     &               + sratio(i,k-1)
 700  CONTINUE
      testmin = 1.E30
      DO 800 i = 1 , 41
         test = abs(softness-srgood(i))
         IF ( test.LT.testmin ) THEN
            testmin = test
            alpha = en(i)
            igood = i
         ENDIF
 800  CONTINUE
      IF ( igood.LE.1 .OR. igood.GE.40 ) THEN
         alpha = -99.
      ELSEIF ( softness.LT.srgood(igood) ) THEN
         alpha = (en(igood+1)-en(igood))/(srgood(igood+1)-srgood(igood))
     &           *(softness-srgood(igood)) + en(igood)
      ELSE
         alpha = (en(igood)-en(igood-1))/(srgood(igood)-srgood(igood-1))
     &           *(softness-srgood(igood-1)) + en(igood-1)
      ENDIF
      RETURN
      END

**==CTS_FLUX210.FOR

      SUBROUTINE cts_flux210(alpha,nh,fluxcts)
c
c returns Swift XRT unabsorbed flux (incident to the Galaxy)
c                                in the 2.0-10.0keV band
c
      INTEGER*4 itime , i , j , k , lu_input , igood
      REAL*4 nh , alpha , softness , soft , test , testmin , fluxcts
      REAL*4 en(41) , nhvalue(20) , ctsflux(41,20) , offset
      LOGICAL ok
      itime = itime + 1
      IF ( alpha.LE.-0.9 .OR. alpha.GE.3.0 ) alpha = 0.8
      IF ( nh.LT.2.E19 .OR. nh.GT.2.E22 ) nh = 3.E20
      IF ( itime.EQ.1 ) THEN
         CALL getlun(lu_input)
         OPEN (lu_input,FILE='xrtflux210_u.dat',STATUS='old')
         READ (lu_input,*,END=100) (nhvalue(j),j=1,20)
         i = 0
         ok = .TRUE.
         DO 50 WHILE (ok)
            i = i + 1
            READ (lu_input,*,END=100) en(i) , (ctsflux(i,j),j=1,20)
 50      CONTINUE
 100     CLOSE (lu_input)
         CALL frelun(lu_input)
      ENDIF
      i = 1
      DO 600 WHILE (alpha.GE.en(i) .AND. i.LT.40)
         i = i + 1
 600  CONTINUE
      j = 1
      DO 700 WHILE (nh.GE.nhvalue(j) .AND. j.LT.20)
         j = j + 1
 700  CONTINUE
      fluxcts = ctsflux(i,j)
      RETURN
      END
**==CTS_FLUX052.FOR

      SUBROUTINE cts_flux052(alpha,nh,fluxcts)
c
c returns Swift XRT unabsorbed flux (incident to the Galaxy)
c                                in the 0.5-2.0keV band
c
      INTEGER*4 itime , i , j , k , lu_input , igood
      REAL*4 nh , alpha , softness , soft , test , testmin , fluxcts
      REAL*4 en(41) , nhvalue(20) , ctsflux(41,20) , offset
      LOGICAL ok
      itime = itime + 1
      IF ( alpha.LE.-0.9 .OR. alpha.GE.3.0 ) alpha = 0.8
      IF ( nh.LT.2.E19 .OR. nh.GT.2.E22 ) nh = 3.E20
      IF ( itime.EQ.1 ) THEN
         CALL getlun(lu_input)
         OPEN (lu_input,FILE='xrtflux052_u.dat',STATUS='old')
         READ (lu_input,*,END=100) (nhvalue(j),j=1,20)
         i = 0
         ok = .TRUE.
         DO 50 WHILE (ok)
            i = i + 1
            READ (lu_input,*,END=100) en(i) , (ctsflux(i,j),j=1,20)
 50      CONTINUE
 100     CLOSE (lu_input)
         CALL frelun(lu_input)
      ENDIF
      i = 1
      DO 600 WHILE (alpha.GE.en(i) .AND. i.LT.40)
         i = i + 1
 600  CONTINUE
      j = 1
      DO 700 WHILE (nh.GE.nhvalue(j) .AND. j.LT.20)
         j = j + 1
 700  CONTINUE
      fluxcts = ctsflux(i,j)
      RETURN
      END
**==CTS_FLUX0124.FOR

      SUBROUTINE cts_flux0124(alpha,nh,fluxcts)
c
c returns Swift XRT absorbed flux (on the detector) in the 0.1-2.4keV band
c
      INTEGER*4 itime , i , j , k , lu_input , igood
      REAL*4 nh , alpha , softness , soft , test , testmin , fluxcts
      REAL*4 en(41) , nhvalue(20) , ctsflux(41,20) , offset
      LOGICAL ok
      itime = itime + 1
      IF ( alpha.LE.-0.9 .OR. alpha.GE.3.0 ) alpha = 0.8
      IF ( nh.LT.2.E19 .OR. nh.GT.2.E22 ) nh = 3.E20
      IF ( itime.EQ.1 ) THEN
         CALL getlun(lu_input)
         OPEN (lu_input,FILE='xrtflux0124.dat',STATUS='old')
         READ (lu_input,*,END=100) (nhvalue(j),j=1,20)
         i = 0
         ok = .TRUE.
         DO 50 WHILE (ok)
            i = i + 1
            READ (lu_input,*,END=100) en(i) , (ctsflux(i,j),j=1,20)
 50      CONTINUE
 100     CLOSE (lu_input)
         CALL frelun(lu_input)
      ENDIF
      i = 1
      DO 600 WHILE (alpha.GE.en(i) .AND. i.LT.40)
         i = i + 1
 600  CONTINUE
      j = 1
      DO 700 WHILE (nh.GE.nhvalue(j) .AND. j.LT.20)
         j = j + 1
 700  CONTINUE
      fluxcts = ctsflux(i,j)
      RETURN
      END

