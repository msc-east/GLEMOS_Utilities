program BCinterpol
    
    use BCparams
    implicit none

    integer(2)  i, j, k, i1, j1, k1, i2, j2, k2, x1, x2, y1, y2, f
    integer Form, Year, Month, Day, Period, Form, FileStat, ios, Src, lenType, idayBg, idayFn
    integer monBg, dayBg, monFn, dayFn
    real longM, latM, dXdX, dYdY, A11, A12, A21, A22, Q11, Q12, Q21, Q22, coef
    character yy*4, mm*2, dd*2
    character(300) strRead, strType, strPar
    character(240) fileName, fullName
    

! Reading configuration file
    print *, 'Reading configuration file...'

    fileConf='./proc_boundary.conf.dat'
    open(1, file=trim(fileConf), status='old', iostat=FileStat, action='read')
    if(FileStat>0) then
      print '(/,"STOP: Cannot open config file ''",a,"''",/)', trim(fileConf)
      stop
    endif

    do
      read(1,'(a)',iostat=ios) strRead
      if(ios==-1) exit

! Recognizing comments
      if(strRead(1:1)=='!'.or.strRead(1:1)==' '.or.strRead(1:1)=='	'.or.ichar(strRead(1:1))==13) cycle
      lenType=scan(strRead,'!')
      if(lenType>0) then
        strRead=strRead(:lenType-1)
      endif

! Deleting tabs and line termination symbols
      lenType=scan(strRead,'	')
      do while (lenType>0)
        strRead=strRead(:lenType-1)//strRead(lenType+1:)
        lenType=scan(strRead,'	')
      enddo	  
      lenType=scan(strRead,achar(13))
      if(lenType>0) strRead=strRead(:lenType-1)

! Reading parameter type
      lenType=scan(strRead,':')
      if(lenType==0) then
        print '(/,"STOP: Wrong format of ''",a,"'' file",/)', trim(fileConf)
        stop
      endif
      strType=trim(strRead(:lenType-1))
      strPar=strRead(lenType+1:)
      strPar=adjustl(strPar)

      selectcase(strType)
        case('Input grid code')
          inGrid=strPar
        case('Output grid code')
          outGrid=strPar
	case('Substance')
	  SubsID=strPar
	case('Year')
          read(strPar,*) Year
	case('Start date')
          read(strPar,'(i4,i2,i2)') Year, monBg, dayBg
	case('Finish date')
          read(strPar,'(i4,i2,i2)') Year, monFn, dayFn
	case('Input file')
	  fileIn=strPar
	case('Grids path')
	  GridPath=strPar
	case('Input path')
	  InPath=strPar
	case('Output path')
	  OutPath=strPar
        case default 
          print '(/,"STOP: Uknown parameter ''",a,"'' in config file ''",a,"''",/)', strType, trim(fileConf)
          stop
      endselect
    enddo

!------------------------------------------------------------------------------------------
! Readung grid config file
    print *, 'Reading grid file...'
    call ReadGrid(inGrid,Imax1,Jmax1,dX1,dY1,xOrig1,yOrig1)
    call ReadGrid(outGrid,Imax2,Jmax2,dX2,dY2,xOrig2,yOrig2)

!------------------------------------------------------------------------------------------
! Readung atmospheric config file
    print *, 'Reading vertical structure...'
    print *

    filename='Atm_config.dat'
    fullName=trim(GridPath)//trim(filename)
    open(1, file=trim(fullName), status='old', iostat=FileStat, action='read')
    if(FileStat>0) then
      print '(/,"STOP: Cannot open Atm config file ''",a,"''",/)', trim(fullName)
      stop 
    endif

    do
      read(1,'(a)',iostat=ios) strRead
      if(ios==-1) exit

! Recognizing comments
      if(strRead(1:1)=='!'.or.strRead(1:1)==' '.or.strRead(1:1)=='	'.or.ichar(strRead(1:1))==13) cycle
      lenType=scan(strRead,'!')
      if(lenType>0) then
        strRead=strRead(:lenType-1)
      endif

! Deleting tabs and line termination symbols
      lenType=scan(strRead,'	')
      do while (lenType>0)
        strRead=strRead(:lenType-1)//strRead(lenType+1:)
        lenType=scan(strRead,'	')
      enddo
      lenType=scan(strRead,achar(13))
      if(lenType>0) strRead=strRead(:lenType-1)

! Reading parameter type
      lenType=scan(strRead,':')
      if(lenType==0) then
        print '(/,"STOP: Wrong format of ''",a,"'' file",/)', trim(fullName)
        stop
      endif
      strType=trim(strRead(:lenType-1))
      strPar=strRead(lenType+1:)
      strPar=adjustl(strPar)

      selectcase(strType)
         case('Number of layers')
          read(strPar,*) Kmax1
      endselect
    enddo
    close(1)
    Kmax2=Kmax1
!-----------------------------------------------------------------------------------------
! Checking for leap year
    if(mod(Year,4)==0) then
        MonthDays(2)=29
    end if
!------------------------------------------------------------------------------------------
    selectcase(SubsID)
    case('Hg')
      NumForm=3
      FormID(1)='_part'
      FormID(2)='II_gas'
      FormID(3)='0_gas'
    case('Pb','Cd')
      NumForm=1
      FormID(1)='_part'
    case('BaP','BbF','BkF','IP','HCB','PCB-153','23PeCDF')
      NumForm=2
      FormID(1)='_gas'
      FormID(2)='_part'
    endselect
        
!------------------------------------------------------------------------------------------
! Read number of sources and their names to allocate arrays
    call BC_read_ncf_init(Year,monBg,dayBg)

    allocate(LonMesh1(Imax1), LatMesh1(Jmax1), LonMesh2(0:Imax2+1), LatMesh2(0:Jmax2+1))
    allocate(Atm_MixRatio1(Imax1,Jmax1,Kmax1,NumForm,4,NumSrc))
    allocate(fld3d(Imax1,Jmax1,Kmax1,NumSrc))
    allocate(Atm_MixRatio2(0:Imax2+1,0:Jmax2+1,Kmax2,NumForm,4,NumSrc))
!------------------------------------------------------------------------------------------
! Definition of horizontal grids
    do j1=1, Jmax1
        LatMesh1(j1)=dY1*(j1-0.5)+yOrig1
        do i1=1, Imax1
            LonMesh1(i1)=dX1*(i1-0.5)+xOrig1
        enddo
    enddo

    do j2=0, Jmax2+1
        LatMesh2(j2)=dY2*(j2-0.5)+yOrig2
        do i2=0, Imax2+1
            LonMesh2(i2)=dX2*(i2-0.5)+xOrig2
        enddo
    enddo

    do Month=monBg, monFn
	if(Month==monBg) then
	   idayBg = dayBg
	else
	   idayBg = 1
	end if 
	if(Month==monFn) then
	   idayFn = dayFn
	else
	   idayFn = MonthDays(Month)
	end if
	do Day=idayBg, idayFn
!        do Day=dayBg, min(dayFn,MonthDays(Month))
            write(DayNum,'(i2.2)') Day
            print *, MonthName(Month), DayNum
!------------------------------------------------------------------------------------------
! Reading original data
            call BC_read_ncf(Year,Month,Day)
!------------------------------------------------------------------------------------------
! Interpolation
        do j2=0, Jmax2+1
          do i2=0, Imax2+1
            longM=LonMesh2(i2)
            latM=LatMesh2(j2)

            do j1=1, Jmax1
              if(LatMesh1(j1)<latM) cycle
              y1=j1-1
              y2=j1
              do i1=1, Imax1
                if(LonMesh1(i1)<longM) cycle
                x1=i1-1
                x2=i1
                exit
              enddo
              dXdX=(longM-LonMesh1(x1))/(LonMesh1(x2)-LonMesh1(x1))
              exit
            enddo
            dYdY=(latM-LatMesh1(y1))/(LatMesh1(y2)-LatMesh1(y1))

            A11=1.-dXdX-dYdY+dXdX*dYdY
            A21=(1.-dYdY)*dXdX
            A12=(1.-dXdX)*dYdY
            A22=dXdX*dYdY
            do Src = 1, NumSrc
            do Period=1, 4
              do Form=1, NumForm
                do k1=1, Kmax1
                    Q11=Atm_MixRatio1(x1,y1,k1,Form,Period,Src)
                    Q12=Atm_MixRatio1(x1,y2,k1,Form,Period,Src)
                    Q21=Atm_MixRatio1(x2,y1,k1,Form,Period,Src)
                    Q22=Atm_MixRatio1(x2,y2,k1,Form,Period,Src)
                    Atm_MixRatio2(i2,j2,k1,Form,Period, Src)=A11*Q11+A21*Q21+A12*Q12+A22*Q22
                    enddo   ! k
              enddo   ! Form
            enddo ! Period
            enddo   ! Src
          enddo ! i
        enddo   ! j
!------------------------------------------------------------------------------------------
! Writing interpolated data
        write(yy, '(i4.4)') Year
        write(mm, '(i2.2)') Month
        write(dd, '(i2.2)') Day
        do f = 1, NumForm
            fileName = trim(SubsID)//trim(FormID(f))//'_bound_'//yy//mm//dd//'.bin'
            fullName=trim(OutPath)//trim(outGrid)//'/'//trim(SubsID)//'/'//trim(yy)//'/'//trim(fileName)
            open(5, file=fullName, action='write', iostat=FileStat,form='unformatted', access="stream")
	    if(FileStat>0) then
    		print '(/,"STOP: Cannot open file ''",a,"''",/)', trim(fullName)
		stop
	    endif
!	    print *, 'Writing: ', NumSrc, Year, Month, Day
            write(5) NumSrc
            Write(5) (SourcID(Src), Src = 1, NumSrc)
            do Src = 1, NumSrc
            do Period=1, 4
              do k2=1, Kmax2
                do j2=0, Jmax2+1
                  write(5) (Atm_MixRatio2(0,j2,k2,f,Period, Src))
                  write(5) (Atm_MixRatio2(Imax2+1,j2,k2,f,Period, Src))
                enddo
                do i2=0, Imax2+1
                  write(5) (Atm_MixRatio2(i2,0,k2,f,Period, Src))
                  write(5) (Atm_MixRatio2(i2,Jmax2+1,k2,f,Period, Src))
                enddo
              enddo
            enddo   ! Period
            enddo   ! Src
            close(5)
        end do ! f
!------------------------------------------------------------------------------------------
      enddo ! days
    enddo ! months
!------------------------------------------------------------------------------------------
    deallocate(LonMesh1, LatMesh1, LonMesh2, LatMesh2, fld3d)
    deallocate(Atm_MixRatio1)
    deallocate(Atm_MixRatio2)
!------------------------------------------------------------------------------------------

end program BCinterpol
