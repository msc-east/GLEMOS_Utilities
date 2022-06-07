!-----------------------------------------------------------------------
! Read nc file to get 3d mix ratio arrays by sources
!-----------------------------------------------------------------------
subroutine BC_read_ncf(yr,mn,da)

    use BCparams
    use netcdf
    implicit none

    integer         yr, mn, da
    integer         per, ncid_in, st, var_id_in, src_dim_id, f, i, j, k, src
    integer         start4(5), count4(5)
    character*32    var_name
    character(240)  fileName, fullName

    write(DayNum,'(i2.2)') da
    do per = 1, 4
        write(PerNum,'(i1)') per

    ! Open input netCDF file
        write(fileName, '(a,a,a1,i4,2i2.2,a1,i2.2,a3)') trim(SubsID), trim(fileIn),'_',yr,mn,da,'_',per,'.nc'
        fullName=trim(InPath)//trim(fileName)
!        print *, 'Reading netcdf file: ',trim(fullName)
	st = nf90_open(trim(fullName),nf90_nowrite,ncid_in)
        if(st /= nf90_noerr) then
            print *, nf90_strerror(st),': ',trim(fullName)
            stop
        end if

        start4=(/1,1,1,1,1/)
        count4=(/Imax1,Jmax1,Kmax1,NumSrc,1/)
        if(NumForm == 0) then
           print *, 'Error. Incorrect NumForm: ',NumForm
           stop
        end if

        do f = 1, NumForm
            var_name = 'mix_ratio_'//trim(SubsID)//trim(FormID(f))
!            print *, var_name

            st = nf90_inq_varid(ncid_in,trim(var_name),var_id_in)
            if(st /= nf90_noerr) then
                print *, 'Error in reading id for variable: ', trim(var_name)
                print *, nf90_strerror(st),': ', trim(fullName)
                stop
            end if

! Read 2d mix ratio for the form f
            st = nf90_get_var(ncid_in,var_id_in,fld3d,start4,count4)
            if(st /= nf90_noerr) then
                print *, 'Error in reading variable: ', trim(var_name)
                print *, nf90_strerror(st),': ', trim(fullName)
                stop
            end if
! Store into array for writing
            do src = 1, NumSrc
                do k = 1, KMax1
                    do j = 1, JMax1
                        do i = 1, IMax1
                            Atm_MixRatio1(i,j,k,f,per,src) = fld3d(i,j,k,src)
                        end do
                    end do
                end do
            end do ! src
        end do

	st = nf90_close(ncid_in)
    end do ! per

end subroutine BC_read_ncf

!-----------------------------------------------------------------------
! Initial read of nc file to get number of sources and their names
!-----------------------------------------------------------------------
subroutine BC_read_ncf_init(yr,mn,da)

    use BCparams
    use netcdf
    implicit none

    integer         yr, mn, da
    integer         per, ncid_in, st, var_id_in, src_dim_id, f
    integer         start1(2), count1(2)
    character*32    var_name
    character*8, allocatable    :: src_names(:)
    character(240)  fileName, fullName

    write(DayNum,'(i2.2)') da
    per = 1
    write(PerNum,'(i1)') per

! Open input netCDF file
    write(fileName, '(a,a,a1,i4,2i2.2,a1,i2.2,a3)') trim(SubsID), trim(fileIn),'_',yr,mn,da,'_',per,'.nc'
    fullName=trim(InPath)//trim(fileName)
!    print *, 'Reading netcdf file: ',trim(fullName)
    st = nf90_open(trim(fullName),nf90_nowrite,ncid_in)
    if(st /= nf90_noerr) then
        print *, nf90_strerror(st),': ', trim(fullName)
        stop
    end if

! Read number of sources and their names
    st = nf90_inq_dimid(ncid_in, "src", src_dim_id)
    st = nf90_inquire_dimension(ncid_in,src_dim_id,len = NumSrc)

!    print *, 'Number of sources: ', NumSrc

    st = nf90_inq_varid(ncid_in,"src_nm",var_id_in)
    if(st /= nf90_noerr) then
        print *, nf90_strerror(st),': ', trim(fullName)
        stop
    end if
    allocate(src_names(NumSrc))

    st = nf90_get_var(ncid_in,var_id_in,src_names(1:NumSrc))
    if(st /= nf90_noerr) then
        print *, nf90_strerror(st),': ', trim(fullName)
        stop
    end if

! Check number of sources and set name BND if the model was run in field mode
    if(NumSrc == 1 .and. int(src_names(1)(1:1)) == 0) then
        src_names(1) = 'BND'
    end if

! Copy sources names to the array for writing
    do f = 1, NumSrc
        SourcID(f) = trim(src_names(f))
    end do

! Save sources names into text file
!    print *, 'Sources: ', src_names
    fileName = trim(SubsID)//'_sources.dat'
    fullName=trim(OutPath)//trim(outGrid)//'/'//trim(fileName)
    open(111, file=trim(fullName), action='write')
    write(111, '(a)') (src_names(f), f = 1, NumSrc)
    close(111)

! Close input netCDF file
    st = nf90_close(ncid_in)
    deallocate(src_names)

end subroutine BC_read_ncf_init

!-----------------------------------------------------------------------
! Reading grid parameters
!-----------------------------------------------------------------------
subroutine ReadGrid(GridCode,Imax,Jmax,dX,dY,xOrig,yOrig)

    use BCparams
    implicit none

    integer Imax, Jmax, lenType, FileStat, ios
    real dX, dY, xOrig, yOrig
    character(20) GridCode 
    character(240) fileName, fullName
    character(300) strRead, strType, strPar

    fileName='Grid_config_'//trim(GridCode)//'.dat'
    fullName=trim(GridPath)//trim(fileName)
    open(1, file=trim(fullName), status='old', iostat=FileStat, action='read')
    if(FileStat>0) then
      print '(/,"STOP: Cannot open grid config file ''",a,"''",/)', trim(fullName)
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
        case('Grid code')
          if(trim(strPar)/=trim(GridCode)) then
            print '(/,"STOP: Wrong grid code - ''",a,"''",/)', trim(strPar)
            stop
          endif
        case('Grid size')
          read(strPar,*) Imax, Jmax           ! Number of grid cells
        case('Grid resolution')
          read(strPar,*) dX, dY 
        case('Grid origin')
          read(strPar,*) xOrig, yOrig           ! Degrees
      endselect
    enddo
    close(1)

end subroutine ReadGrid
