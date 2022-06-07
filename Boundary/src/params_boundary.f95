module BCparams
    
    implicit none

    real(8), parameter :: Rearth=6370.e3, piNum=3.141592653589793_8, pi180=1.74532925199433e-2_8
    
! Original grid
    integer     Imax1, Jmax1, Kmax1
    real        dX1, dY1, xOrig1, yOrig1
! Final grid
    integer     Imax2, Jmax2, Kmax2
    real        dX2, dY2, xOrig2, yOrig2

    integer, parameter :: MaxForm=3
    integer NumForm

    real, allocatable :: LonMesh1(:), LatMesh1(:), LonMesh2(:), LatMesh2(:)
    real, allocatable :: Atm_MixRatio1(:,:,:,:,:,:)
    real, allocatable :: Atm_MixRatio2(:,:,:,:,:,:)
    real, allocatable :: fld3d(:,:,:,:)

    character(20)  inGrid, outGrid
    character(240) InPath, OutPath, GridPath, fileIn, fileOut, fileConf
    character(4) YearNum, DayNum, PerNum
    character(3) MonthName(12)
    data MonthName /'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'/
    integer MonthDays(12)
    data MonthDays /31,28,31,30,31,30,31,31,30,31,30,31/
    character(10) SubsID, FormID(MaxForm)

    integer, parameter :: MaxSrc=70
    integer NumSrc
    character(8) SourcID(MaxSrc)

end module BCparams