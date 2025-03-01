c
c
c     ##########################################################
c     ##  COPYRIGHT (C) 2014 by Chao Lu & Jay William Ponder  ##
c     ##                  All Rights Reserved                 ##
c     ##########################################################
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine eangtor3  --  angle-torsion energy & analysis  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "eangtor3" calculates the angle-torsion potential energy;
c     also partitions the energy terms among the atoms
c
c
      subroutine eangtor3
      use action
      use analyz
      use angbnd
      use angtor
      use atomid
      use atoms
      use bound
      use energi
      use group
      use inform
      use iounit
      use math
      use torpot
      use tors
      use usage
      use mndo
      implicit none
      integer i,k,iangtor
      integer ia,ib,ic,id
      real*8 e,e1,e2
      real*8 rcb,fgrp
      real*8 rt2,ru2,rtru
      real*8 rba2,rcb2,rdc2
      real*8 dot,dt,tangle
      real*8 xt,yt,zt
      real*8 xu,yu,zu
      real*8 xtu,ytu,ztu
      real*8 v1,v2,v3
      real*8 c1,c2,c3
      real*8 s1,s2,s3
      real*8 sine,cosine
      real*8 sine2,cosine2
      real*8 sine3,cosine3
      real*8 phi1,phi2,phi3
      real*8 angle,cosang
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 xid,yid,zid
      real*8 xba,yba,zba
      real*8 xcb,ycb,zcb
      real*8 xdc,ydc,zdc
      logical proceed
      logical header,huge
c
c
c     zero out the energy due to extra potential terms
c
      neat = 0
      eat = 0.0d0
      do i = 1, n
         aeat(i) = 0.0d0
      end do
      if (nangtor .eq. 0)  return
c
c     print header information if debug output was requested
c
      header = .true.
      if (debug .and. nangtor.ne.0) then
         header = .false.
         write (iout,10)
   10    format (/,' Individual Angle-Torsion Interactions :',
     &           //,' Type',25x,'Atom Names',21x,'Angle',
     &              6x,'Energy',/)
      end if
c
c     OpenMP directives for the major loop structure
c
!$OMP PARALLEL default(private) shared(nangtor,iat,itors,kant,anat,
!$OMP& tors1,tors2,tors3,use,x,y,z,atorunit,use_group,use_polymer,
!$OMP& name,verbose,debug,header,iout)
!$OMP& shared(eat,neat,aeat,isqm)
!$OMP DO reduction(+:eat,neat,aeat) schedule(guided)
c
c     calculate the angle-torsion interaction energy term
c
      do iangtor = 1, nangtor
         i = iat(1,iangtor)
         ia = itors(1,i)
         ib = itors(2,i)
         ic = itors(3,i)
         id = itors(4,i)
c
c     skip interaction if one of the atoms is qm
c
         if (isqm(ia).or.isqm(ib).or.isqm(ic).or.
     $    isqm(id)) cycle
c
c     decide whether to compute the current interaction
c
         proceed = .true.
         if (use_group)  call groups (proceed,fgrp,ia,ib,ic,id,0,0)
         if (proceed)  proceed = (use(ia) .or. use(ib) .or.
     &                              use(ic) .or. use(id))
c
c     compute the value of the torsional angle
c
         if (proceed) then
            xia = x(ia)
            yia = y(ia)
            zia = z(ia)
            xib = x(ib)
            yib = y(ib)
            zib = z(ib)
            xic = x(ic)
            yic = y(ic)
            zic = z(ic)
            xid = x(id)
            yid = y(id)
            zid = z(id)
            xba = xib - xia
            yba = yib - yia
            zba = zib - zia
            xcb = xic - xib
            ycb = yic - yib
            zcb = zic - zib
            xdc = xid - xic
            ydc = yid - yic
            zdc = zid - zic
            if (use_polymer) then
               call image (xba,yba,zba)
               call image (xcb,ycb,zcb)
               call image (xdc,ydc,zdc)
            end if
            rba2 = xba*xba + yba*yba + zba*zba
            rcb2 = xcb*xcb + ycb*ycb + zcb*zcb
            rdc2 = xdc*xdc + ydc*ydc + zdc*zdc
            if (min(rba2,rcb2,rdc2) .ne. 0.0d0) then
               xt = yba*zcb - ycb*zba
               yt = zba*xcb - zcb*xba
               zt = xba*ycb - xcb*yba
               xu = ycb*zdc - ydc*zcb
               yu = zcb*xdc - zdc*xcb
               zu = xcb*ydc - xdc*ycb
               xtu = yt*zu - yu*zt
               ytu = zt*xu - zu*xt
               ztu = xt*yu - xu*yt
               rt2 = xt*xt + yt*yt + zt*zt
               rt2 = max(rt2,0.000001d0)
               ru2 = xu*xu + yu*yu + zu*zu
               ru2 = max(ru2,0.000001d0)
               rtru = sqrt(rt2*ru2)
               rcb = sqrt(rcb2)
               cosine = (xt*xu + yt*yu + zt*zu) / rtru
               sine = (xcb*xtu + ycb*ytu + zcb*ztu) / (rcb*rtru)
               tangle = radian * acos(cosine)
               if (sine .lt. 0.0d0)  tangle = -tangle
c
c     compute multiple angle trigonometry and phase terms
c
               c1 = tors1(3,i)
               s1 = tors1(4,i)
               c2 = tors2(3,i)
               s2 = tors2(4,i)
               c3 = tors3(3,i)
               s3 = tors3(4,i)
               cosine2 = cosine*cosine - sine*sine
               sine2 = 2.0d0 * cosine * sine
               cosine3 = cosine*cosine2 - sine*sine2
               sine3 = cosine*sine2 + sine*cosine2
               phi1 = 1.0d0 + (cosine*c1 + sine*s1)
               phi2 = 1.0d0 + (cosine2*c2 + sine2*s2)
               phi3 = 1.0d0 + (cosine3*c3 + sine3*s3)
c
c     get the angle-torsion values for the first angle
c
               v1 = kant(1,iangtor)
               v2 = kant(2,iangtor)
               v3 = kant(3,iangtor)
               k = iat(2,iangtor)
               dot = xba*xcb + yba*ycb + zba*zcb
               cosang = -dot / sqrt(rba2*rcb2)
               angle = radian * acos(cosang)
               dt = angle - anat(k)
               e1 = atorunit * dt * (v1*phi1 + v2*phi2 + v3*phi3)
c
c     get the angle-torsion values for the second angle
c
               v1 = kant(4,iangtor)
               v2 = kant(5,iangtor)
               v3 = kant(6,iangtor)
               k = iat(3,iangtor)
               dot = xcb*xdc + ycb*ydc + zcb*zdc
               cosang = -dot / sqrt(rcb2*rdc2)
               angle = radian * acos(cosang)
               dt = angle - anat(k)
               e2 = atorunit * dt * (v1*phi1 + v2*phi2 + v3*phi3)
c
c     scale the interaction based on its group membership
c
               if (use_group) then
                  e1 = e1 * fgrp
                  e2 = e2 * fgrp
               end if
c
c     increment the total angle-torsion energy
c
               neat = neat + 1
               e = e1 + e2
               eat = eat + e
               aeat(ia) = aeat(ia) + e1/3.0d0
               aeat(ib) = aeat(ib) + e/3.0d0
               aeat(ic) = aeat(ic) + e/3.0d0
               aeat(id) = aeat(id) + e2/3.0d0
c
c     print a message if the energy of this interaction is large
c
               huge = (e .gt. 3.0d0)
               if (debug .or. (verbose.and.huge)) then
                  if (header) then
                     header = .false.
                     write (iout,20)
   20                format (/,' Individual Angle-Torsion',
     &                          ' Interactions :',
     &                       //,' Type',25x,'Atom Names',21x,'Angle',
     &                          6x,'Energy',/)
                  end if
                  write (iout,30)  ia,name(ia),ib,name(ib),ic,
     &                             name(ic),id,name(id),tangle,e
   30             format (' AngTors',3x,4(i7,'-',a3),f11.4,f12.4)
               end if
            end if
         end if
      end do
c
c     OpenMP directives for the major loop structure
c
!$OMP END DO
!$OMP END PARALLEL
      return
      end
