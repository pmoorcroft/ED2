!------------------------------------------------------------------------!
!                                                                        !
! Main subroutine for driving the initialization process for             !
! the Ecosystem Demography Model 2.  All compute nodes, including        !
! the node formerly known as master.                                     !
!                                                                        !
!------------------------------------------------------------------------!

subroutine ed_coup_driver()
  
  use grid_coms, only: &
       ngrids,          &
       time,            &
       timmax
  
  use mem_edcp,only:    &
       wgridf_g,        &
       wgridp_g,        &
       wgrids_g,        &
       ed_fluxp_g,      &
       ed_fluxf_g,      &
       ed_precip_g

  use ed_state_vars, only: &
       allocate_edglobals, &    ! implicitly interfaced subroutine
       filltab_alltypes, &
       edgrid_g
  
  use misc_coms, only: &
       iyeara,          &
       imontha,         &
       idatea,          &
       itimea,          &
       runtype,         &
       idoutput,        &
       imoutput,        &
       integration_scheme

  use soil_coms, only: alloc_soilgrid
  use ed_node_coms , only: mynum,nnodetot,sendnum,recvnum,mmxp,mmyp

  implicit none
  real :: w1,w2,w3,wtime_start  ! wall time
  real, external :: walltime    ! wall time
  real :: t1,t2                 ! cpu time
  character(len=12) :: c0
  character(len=12) :: c1
  integer :: i,j,ifm,nndtflg,ipy

  integer :: id1,id2,jd1,jd2
  character(len=24) :: fmts1

  !   MPI header
  include 'mpif.h'

  integer                                   :: ierr
  integer :: igr
  integer :: ping 

  ping = 741776

  wtime_start=walltime(0.)
  w1=walltime(wtime_start)


  !---------------------------------------------------------------------------!
  ! STEP 1: Set the ED model parameters                                       !
  !---------------------------------------------------------------------------!
  if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] Load_Ed_Ecosystem_Params...'
  call load_ed_ecosystem_params()
  
  !---------------------------------------------------------------------------!
  ! STEP 2: Overwrite the parameters in case a XML file is provided           !
  !---------------------------------------------------------------------------!

  if (mynum /= 1) call MPI_RECV(ping,1,MPI_INTEGER,recvnum,602,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
  if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Checking for XML config...'
  
  call overwrite_with_xml_config(mynum)
  
  if (mynum < nnodetot ) call MPI_Send(ping,1,MPI_INTEGER,sendnum,602,MPI_COMM_WORLD,ierr)

!  if (nnodetot /= 1 ) call MPI_Barrier(MPI_COMM_WORLD,ierr)
  
  !---------------------------------------------------------------------------!
  ! STEP 3: Allocate soil grid arrays                                         !
  !---------------------------------------------------------------------------!
  
  if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] Alloc_Soilgrid...'
  call alloc_soilgrid()
  
  !---------------------------------------------------------------------------------!
  ! STEP 4: Set some polygon-level basic information, such as lon/lat/soil texture  !
  !---------------------------------------------------------------------------------!
  
  if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] Set_Polygon_Coordinates_Ar...'
  call set_polygon_coordinates_ar()
  
  !---------------------------------------------------------------------------!
  ! STEP 5: Initialize inherent soil and vegetation properties.               !
  !---------------------------------------------------------------------------!
  
  if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] Sfcdata_ED...'
  call sfcdata_ed()
  
  
  if (trim(runtype) == 'HISTORY') then
       
 
     !-----------------------------------------------------------------------!
     ! STEP 6A: Initialize the model state as a replicate image of a previous
     !          state.
     !-----------------------------------------------------------------------!

     if (mynum /= 1) call MPI_Recv(ping,1,MPI_INTEGER,recvnum,606,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
  
     if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Init_Full_History_Restart...'
     call init_full_history_restart()
     
     if (mynum < nnodetot ) call MPI_Send(ping,1,MPI_INTEGER,sendnum,606,MPI_COMM_WORLD,ierr)
!     if (nnodetot /= 1 ) call MPI_Barrier(MPI_COMM_WORLD,ierr)
     
     
  else
     
     !------------------------------------------------------------------------!
     ! STEP 6B: Initialize state properties of polygons/sites/patches/cohorts !
     !------------------------------------------------------------------------!
     
     if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Load_Ecosystem_State...'
     call load_ecosystem_state()

  end if

  !--------------------------------------------------------------------------------!
  ! STEP 7: Initialize hydrology related variables                                 !
  !--------------------------------------------------------------------------------!

  if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Initializing Hydrology...'
  call initHydrology()

  !-----------------------------------------------------------------------!
  ! STEP 16: Initialize the flux arrays that pass to the atmosphere
  !-----------------------------------------------------------------------!
  if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Allocating Transfer Arrays...'
  allocate(wgridf_g(ngrids))
  allocate(wgridp_g(ngrids))
  allocate(ed_fluxp_g(ngrids))
  allocate(ed_fluxf_g(ngrids))
  allocate(wgrids_g(ngrids))
  allocate(ed_precip_g(ngrids))
  do ifm=1,ngrids
     call newgrid(ifm)
     call initialize_ed2leaf(ifm,mmxp(ifm),mmyp(ifm))
  enddo

  !-----------------------------------------------------------------------!
  ! STEP 8: Inform edtypes which atmospheric cell to look at
  !          
  !-----------------------------------------------------------------------!
  if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Setting the correspondent atmospheric cells...'
  do ifm=1,ngrids
     call set_edtype_atm(ifm)
  enddo

  !-----------------------------------------------------------------------!
  ! STEP 9: Initialize meteorology                                        !
  !-----------------------------------------------------------------------!
  
  if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] Initializing meteorology...'
  do ifm = 1,ngrids
     call newgrid(ifm)
     call copy_atm2lsm(ifm,.true.)
  enddo

     
  !-----------------------------------------------------------------------!
  ! STEP 10. Initialize ed fields that depend on the atmosphere
  !-----------------------------------------------------------------------!
  
  if (trim(runtype) /= 'HISTORY') then
     if (mynum == nnodetot) write (unit=*,fmt='(a)') ' [+] ed_init_coup_atm...'
     call ed_init_coup_atm
  endif

  !-----------------------------------------------------------------------!
  ! STEP 10.5. Initialize upwelling long wave and albedo
  !            from sst and air temperature.
  !-----------------------------------------------------------------------!
  
  call ed_init_radiation



  !-----------------------------------------------------------------------!
  ! STEP 11. Initialized some derived variables. This must be done        !
  !          outside init_full_history_restart because it depends on some !
  !          meteorological variables that are initialized at step 9.     !
  !-----------------------------------------------------------------------!
  if (trim(runtype) == 'HISTORY') then
     do ifm=1,ngrids
        call update_derived_props(edgrid_g(ifm))
     end do
  end if
  
  !-----------------------------------------------------------------------!
  ! STEP 12. Fill the variable data-tables with all of the state          !
  !          data.  Also calculate the indexing of the vectors            !
  !          to allow for segmented I/O of hyperslabs and referencing     !
  !          of high level hierarchical data types with their parent      !
  !          types.                                                       !
  !-----------------------------------------------------------------------!
  
  if (mynum == 1) write (unit=*,fmt='(a)') ' [+] Filltab_Alltypes...'
  call filltab_alltypes

  !-----------------------------------------------------------------------!
  ! STEP 13. Checking how the output was configure and determining the    !
  !          averaging frequency.                                         !
  !-----------------------------------------------------------------------!
  if (mynum == 1) write(unit=*,fmt='(a)') ' [+] Finding frqsum...'
  call find_frqsum()

  !-----------------------------------------------------------------------!
  ! STEP 14. Zero and initialize diagnostic output variables              !
  !-----------------------------------------------------------------------!

  if (imoutput > 0) then
     do ifm=1,ngrids
        call zero_ed_monthly_output_vars(edgrid_g(ifm))
        call zero_ed_daily_output_vars(edgrid_g(ifm))
     end do
  elseif (idoutput > 0) then
     do ifm=1,ngrids
        call zero_ed_daily_output_vars(edgrid_g(ifm))
     end do
  end if

  !-----------------------------------------------------------------------!
  ! STEP 15: Allocate memory to the integration patch
  !-----------------------------------------------------------------------!
  if(integration_scheme == 1) call initialize_rk4patches_ar(1)
  do ifm=1,ngrids
     call reset_averaged_vars(edgrid_g(ifm))
  end do

   !-----------------------------------------------------------------------!
  ! STEP 17. Getting the CPU time and printing the banner                 !
  !-----------------------------------------------------------------------!
  if (mynum == nnodetot) then
     call timing(1,t1)
     w2=walltime(wtime_start)
     write(c0,'(f12.2)') t1
     write(c1,'(f12.2)') w2-w1
     write(*,'(/,a,/)') ' === Finish initialization of the ED2 LSM; CPU(sec)='//&
          trim(adjustl(c0))//'; Wall(sec)='//trim(adjustl(c1))//&
          '; Time integration starts (ed_master) ===' 
  endif

  return
end subroutine ed_coup_driver

!=========================================================================!
!=========================================================================!

subroutine find_frqsum()
   use misc_coms, only:  &
        isoutput,        &
        ifoutput,         &
        imoutput,        &
        idoutput,        &
        frqstate,         &
        frqfast,          &
        frqsum
   use consts_coms, only: day_sec

   implicit none 

   ! Determining which frequency I should use to normalize variables.
   if (ifoutput == 0 .and. isoutput == 0 .and. idoutput == 0 .and. imoutput == 0) then
         write(unit=*,fmt='(a)') '---------------------------------------------------------'
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! '
         write(unit=*,fmt='(a)') '---------------------------------------------------------'
         write(unit=*,fmt='(a)') ' You are running a simulation that will have no output...'
         frqsum=day_sec ! Just for avoiding build up, 
   elseif (isoutput == 0 .and. ifoutput == 0) then
       frqsum=day_sec
   elseif (isoutput > 0 .and. ifoutput == 0) then
       frqsum=min(frqstate,day_sec)
   elseif (ifoutput > 0 .and. isoutput == 0) then
       frqsum=min(frqfast,day_sec)
   else ! If both are on. If both are off the simulation won't reach this point.
       frqsum=min(min(frqstate,frqfast),day_sec)
   end if
   return
end subroutine find_frqsum

!==========================================================================================!
!==========================================================================================!

subroutine set_edtype_atm(ifm)

    use ed_work_vars,only:work_e
    use ed_state_vars,only:edtype,edgrid_g
    use ed_node_coms,only:mmxp,mmyp
    
    implicit none

    integer :: ipy,i,j,ifm
    type(edtype),pointer :: cgrid

    cgrid=>edgrid_g(ifm)

    ipy = 0
    do i=1,mmxp(ifm)
       do j = 1,mmyp(ifm)
          if (work_e(ifm)%land(i,j)) then
             ipy = ipy + 1
             cgrid%ilon(ipy) = work_e(ifm)%xatm(i,j)
             cgrid%ilat(ipy) = work_e(ifm)%yatm(i,j)
          endif
       enddo
    enddo

    return
  end subroutine set_edtype_atm