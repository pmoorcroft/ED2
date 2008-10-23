!###########################################################################

  ! Each unique combination will have a call number associated with it.
  !
  ! 11  : rank 1 : polygon (real)
  ! 12  : rank 2 : polygon, s-layer
  ! 13  : rank 2 : polygon, w-layer
  ! 14  : rank 2 : polygon, pft
  ! 146 : rank 3 : polygon, npft,ndbh
  ! 15  : rank 2 : polygon, disturbance
  ! 16  : rank 2 : polygon, dbh
  ! 155 : rank 2 : polygon, max_lu_years
  ! 156 : rank 3 : polygon, max_lu_years, num_lu_transitions
  !
  ! 20  : rank 1 : site (integer)
  ! 21  : rank 1 : site (real)
  ! 22  : rank 2 : site, s-layer
  ! 23  : rank 2 : site, w-layer
  ! 24  : rank 2 : site, pft
  ! 246 : rank 3 : site, pft, dbh
  ! 25  : rank 2 : site, disturbance
  ! 255 : rank 3 : site, disturbance,disturbance
  ! 26  : rank 2 : site, dbh
  ! 28  : rank 2 : site, months
  !
  ! 30  : rank 1 : patch (integer)
  ! 31  : rank 1 : patch (real)
  ! 32  : rank 2 : patch, s-layer
  ! 33  : rank 2 : patch, w-layer
  ! 34  : rank 2 : patch, pft
  ! 347 : rank 3 : patch, pft,ff_dbh
  ! 35  : rank 2 : patch, disturbance
  ! 36  : rank 2 : patch, dbh
  !
  ! 41  : rank 1 : cohort (real)
  ! 44  : rank 2 : cohort, pft
  ! 46  : rank 2 : cohort, dbh
  ! 49  : rank 2 : cohort, nmonths+1
  
  ! 90 is a special flag for scalars
Module var_tables_array
  
  !    Define data type for main variable table
  integer,parameter :: maxvars = 1500
  
  type var_table
     
     integer :: idim_type
     integer :: nptrs
     integer :: ihist,ianal,imean,ilite,impti,impt1,impt2,impt3,irecycle,iyear
     character (len=64) :: name
     character (len=2) :: dtype
     integer :: imont,idail
     logical :: first
     integer :: var_len_global
     character (len=64) :: lname   ! Long name for description in file
     character (len=16)  :: units   ! Unit description of the data
     character (len=64)  :: dimlab
     
     !    Multiple pointer defs (maxptrs)
     type(var_table_vector),pointer,dimension(:) :: vt_vector

  end type var_table

    
  type var_table_vector

     real, pointer :: var_rp    
     integer, pointer :: var_ip
     character (len=256),pointer :: var_cp
     integer :: globid
     integer :: varlen
     
  end type var_table_vector

  
  !    Main variable table allocated to (maxvars,maxgrds)
  type(var_table), allocatable :: vt_info(:,:)


  !    number of variables for each grid, allocated to "ngrids"
  integer, allocatable :: num_var(:)

contains

  recursive subroutine vtable_edio_r( &
       var,      &    ! The pointer of the current state variable
       nv,       &    ! The variable type number
       igr,      &    ! The number of the current grid
       init,     &    ! Initialize the vt_info?
       glob_id,  &    ! The global index of the data
       var_len,  &    ! The length of the states current vector
       var_len_global, & ! THe length of the entire dataset's vector
       max_ptrs,  &    ! The maximum possible number of pointers
       ! necessary for this variable
       tabstr)        ! The string describing the variables usage
    
    implicit none
    
    real,target :: var
    
    integer :: init
    integer :: var_len,var_len_global,max_ptrs,glob_id,iptr,igr
    character (len=*) :: tabstr
    
    character (len=1) ::toksep=':', cdimen,ctype
    character (len=128) ::tokens(10)
    character (len=8) :: ctab
    integer :: ntok,nt,nv
    
    ! ------------------------------------------------
    ! Determine if this is the first
    ! time we view this variable.  If so, then
    ! fill some descriptors for the vtable
    ! and allocate some space for any pointers
    ! that may follow
    ! ------------------------------------------------
    
    if (init == 0) then
       
       ! Count the number of variables
       num_var(igr) = num_var(igr) + 1
      
       call tokenize1(tabstr,tokens,ntok,toksep)
       
       vt_info(nv,igr)%name=tokens(1)

!       print*,num_var(igr),nv,trim(vt_info(nv,igr)%name)

       vt_info(nv,igr)%dtype='r'  ! This is a real variable

       vt_info(nv,igr)%nptrs = 0
       
       vt_info(nv,igr)%var_len_global = var_len_global

       allocate(vt_info(nv,igr)%vt_vector(max_ptrs))
       
       read(tokens(2),*) vt_info(nv,igr)%idim_type
       
       vt_info(nv,igr)%ihist=0
       vt_info(nv,igr)%ianal=0
       vt_info(nv,igr)%imean=0
       vt_info(nv,igr)%ilite=0
       vt_info(nv,igr)%impti=0
       vt_info(nv,igr)%impt1=0
       vt_info(nv,igr)%impt2=0
       vt_info(nv,igr)%impt3=0
       vt_info(nv,igr)%irecycle=0
       vt_info(nv,igr)%imont=0
       vt_info(nv,igr)%idail=0
       vt_info(nv,igr)%iyear=0
       
       do nt=3,ntok
          ctab=tokens(nt)
          
          select case (trim(ctab))
          case('hist') 
             vt_info(nv,igr)%ihist=1
          case('anal') 
             vt_info(nv,igr)%ianal=1
          case('lite') 
             vt_info(nv,igr)%ilite=1
          case('mpti') 
             vt_info(nv,igr)%impti=1
          case('mpt1') 
             vt_info(nv,igr)%impt1=1
          case('mpt2') 
             vt_info(nv,igr)%impt2=1
          case('mpt3') 
             vt_info(nv,igr)%impt3=1
          case('recycle') 
             vt_info(nv,igr)%irecycle=1
          case('mont') 
             vt_info(nv,igr)%imont=1
          case('dail') 
             vt_info(nv,igr)%idail=1
          case('year') 
             vt_info(nv,igr)%iyear=1
          case default
             print*, 'Illegal table specification for var:', tokens(1),ctab
             call fatal_error('Bad var table','vtable_edio_r','var_tables_array.f90')
          end select
          
       enddo
       
       ! Set the first pass logical to false
        
    else
       !    Make sure that vt_info is associated. If not, call the function with init = 0 then 
       ! do this part. Since I think this should never happen, I will also make a fuss to warn 
       ! the user
       if (.not.associated(vt_info(nv,igr)%vt_vector)) then
         write (unit=*,fmt='(a)') ' '
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! In subroutine vtable_edio_r (file var_tables_array.f90)                 !'
         write (unit=*,fmt='(a,1x,i4,1x,a,1x,i2,1x,a)')  &
                                  '! Vt_vector for variable',nv,'of grid',igr,'is not associated                !'
         write (unit=*,fmt='(a)') '! I will allocate it now.                                                 !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') ' '
         call vtable_edio_r(var,nv,igr,0,glob_id,var_len,var_len_global,max_ptrs,tabstr)
       end if
       
       vt_info(nv,igr)%nptrs = vt_info(nv,igr)%nptrs + 1
       iptr = vt_info(nv,igr)%nptrs
       
       vt_info(nv,igr)%vt_vector(iptr)%globid = glob_id
       vt_info(nv,igr)%vt_vector(iptr)%var_rp   => var
       vt_info(nv,igr)%vt_vector(iptr)%varlen = var_len

    end if
    
    
    return
  end subroutine vtable_edio_r
!==============================================================================!
!==============================================================================!






!==============================================================================!
!==============================================================================!
  recursive subroutine vtable_edio_i( &
       var,      &    ! The pointer of the current state variable
       nv,       &    ! The variable type number
       igr,      &    ! The number of the current grid
       init,     &    ! Initialize the vt_info?
       glob_id,  &    ! The global index of the data
       var_len,  &    ! The length of the states current vector
       var_len_global, & ! THe length of the entire dataset's vector
       max_ptrs,  &    ! The maximum possible number of pointers
       ! necessary for this variable
       tabstr)        ! The string describing the variables usage
    
    implicit none
    
    integer,target :: var
    
    integer :: init
    integer :: var_len,var_len_global,max_ptrs,glob_id,iptr,igr
    character (len=*) :: tabstr
    
    character (len=1) ::toksep=':', cdimen,ctype
    character (len=128) ::tokens(10)
    character (len=8) :: ctab
    
    integer :: ntok,nt,nv
    
    ! ------------------------------------------------
    ! Determine if this is the first
    ! time we view this variable.  If so, then
    ! fill some descriptors for the vtable
    ! and allocate some space for any pointers
    ! that may follow
    ! ------------------------------------------------
    if (init == 0) then
       
       ! Count the number of variables
       num_var(igr) = num_var(igr) + 1

       call tokenize1(tabstr,tokens,ntok,toksep)
       
       vt_info(nv,igr)%name=tokens(1)

!       print*,num_var(igr),nv,trim(vt_info(nv,igr)%name)

       vt_info(nv,igr)%dtype='i'  ! This is an integer variable

       vt_info(nv,igr)%nptrs = 0
       
       vt_info(nv,igr)%var_len_global = var_len_global

       allocate(vt_info(nv,igr)%vt_vector(max_ptrs))
       
       read(tokens(2),*) vt_info(nv,igr)%idim_type
       
       vt_info(nv,igr)%ihist=0
       vt_info(nv,igr)%ianal=0
       vt_info(nv,igr)%imean=0
       vt_info(nv,igr)%ilite=0
       vt_info(nv,igr)%impti=0
       vt_info(nv,igr)%impt1=0
       vt_info(nv,igr)%impt2=0
       vt_info(nv,igr)%impt3=0
       vt_info(nv,igr)%irecycle=0
       vt_info(nv,igr)%imont=0
       vt_info(nv,igr)%idail=0
       vt_info(nv,igr)%iyear=0
       
       do nt=3,ntok
          ctab=tokens(nt)
          
          select case (trim(ctab))
          case('hist') 
             vt_info(nv,igr)%ihist=1
          case('anal') 
             vt_info(nv,igr)%ianal=1
          case('lite') 
             vt_info(nv,igr)%ilite=1
          case('mpti') 
             vt_info(nv,igr)%impti=1
          case('mpt1') 
             vt_info(nv,igr)%impt1=1
          case('mpt2') 
             vt_info(nv,igr)%impt2=1
          case('mpt3') 
             vt_info(nv,igr)%impt3=1
          case('recycle') 
             vt_info(nv,igr)%irecycle=1
          case('mont') 
             vt_info(nv,igr)%imont=1
          case('dail') 
             vt_info(nv,igr)%idail=1
          case('year') 
             vt_info(nv,igr)%iyear=1
          case default
             print*, 'Illegal table specification for var:', tokens(1),ctab
             call fatal_error('Bad var table','vtable_edio_i','var_tables_array.f90')
          end select
          
       enddo
       
       ! Set the first pass logical to false
       
       vt_info(nv,igr)%first = .false.
       
    else
       !    Make sure that vt_info is associated. If not, call the function with init = 0 then 
       ! do this part. Since I think this should never happen, I will also make a fuss to warn 
       ! the user
       if (.not.associated(vt_info(nv,igr)%vt_vector)) then
         write (unit=*,fmt='(a)') ' '
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! In subroutine vtable_edio_i (file var_tables_array.f90)                 !'
         write (unit=*,fmt='(a,1x,i4,1x,a,1x,i2,1x,a)')  &
                                  '! Vt_vector for variable',nv,'of grid',igr,'is not associated                !'
         write (unit=*,fmt='(a)') '! I will allocate it now.                                                 !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') ' '
         call vtable_edio_i(var,nv,igr,0,glob_id,var_len,var_len_global,max_ptrs,tabstr)
       end if
       vt_info(nv,igr)%nptrs = vt_info(nv,igr)%nptrs + 1
       iptr = vt_info(nv,igr)%nptrs
       vt_info(nv,igr)%vt_vector(iptr)%globid = glob_id
       vt_info(nv,igr)%vt_vector(iptr)%var_ip   => var
       vt_info(nv,igr)%vt_vector(iptr)%varlen = var_len

    endif

    
    return
  end subroutine vtable_edio_i

  ! =====================================================

  recursive subroutine vtable_edio_c( &
       var,      &    ! The pointer of the current state variable
       nv,       &    ! The variable type number
       igr,      &    ! The number of the current grid
       init,     &    ! Initialize the vt_info?
       glob_id,  &    ! The global index of the data
       var_len,  &    ! The length of the states current vector
       var_len_global, & ! THe length of the entire dataset's vector
       max_ptrs,  &    ! The maximum possible number of pointers
       ! necessary for this variable
       tabstr)        ! The string describing the variables usage
    
    implicit none
    
    character (len=256),target :: var
    
    integer :: init
    integer :: var_len,var_len_global,max_ptrs,glob_id,iptr,igr
    character (len=*) :: tabstr
    
    character (len=1) ::toksep=':', cdimen,ctype
    character (len=128) ::tokens(10)
    character (len=8) :: ctab
    integer :: ntok,nt,nv
    
    ! ------------------------------------------------
    ! Determine if this is the first
    ! time we view this variable.  If so, then
    ! fill some descriptors for the vtable
    ! and allocate some space for any pointers
    ! that may follow
    ! ------------------------------------------------
    
    if (init == 0) then
       
       ! Count the number of variables
       num_var(igr) = num_var(igr) + 1
      
       call tokenize1(tabstr,tokens,ntok,toksep)
       
       vt_info(nv,igr)%name=tokens(1)

!       print*,num_var(igr),nv,trim(vt_info(nv,igr)%name)

       vt_info(nv,igr)%dtype='c'  ! This is a string variable

       vt_info(nv,igr)%nptrs = 0
       
       vt_info(nv,igr)%var_len_global = var_len_global

       allocate(vt_info(nv,igr)%vt_vector(max_ptrs))
       
       read(tokens(2),*) vt_info(nv,igr)%idim_type
       
       vt_info(nv,igr)%ihist=0
       vt_info(nv,igr)%ianal=0
       vt_info(nv,igr)%imean=0
       vt_info(nv,igr)%ilite=0
       vt_info(nv,igr)%impti=0
       vt_info(nv,igr)%impt1=0
       vt_info(nv,igr)%impt2=0
       vt_info(nv,igr)%impt3=0
       vt_info(nv,igr)%irecycle=0
       vt_info(nv,igr)%imont=0
       vt_info(nv,igr)%idail=0
       vt_info(nv,igr)%iyear=0
       
       do nt=3,ntok
          ctab=tokens(nt)
          
          select case (trim(ctab))
          case('hist') 
             vt_info(nv,igr)%ihist=1
          case('anal') 
             vt_info(nv,igr)%ianal=1
          case('lite') 
             vt_info(nv,igr)%ilite=1
          case('mpti') 
             vt_info(nv,igr)%impti=1
          case('mpt1') 
             vt_info(nv,igr)%impt1=1
          case('mpt2') 
             vt_info(nv,igr)%impt2=1
          case('mpt3') 
             vt_info(nv,igr)%impt3=1
          case('recycle') 
             vt_info(nv,igr)%irecycle=1
          case('mont') 
             vt_info(nv,igr)%imont=1
          case('dail') 
             vt_info(nv,igr)%idail=1
          case('year') 
             vt_info(nv,igr)%iyear=1
          case default
             print*, 'Illegal table specification for var:', tokens(1),ctab
             call fatal_error('Bad var table','vtable_edio_c','var_tables_array.f90')
          end select
          
       enddo
       
       ! Set the first pass logical to false
        
    else
       !    Make sure that vt_info is associated. If not, call the function with init = 0 then 
       ! do this part. Since I think this should never happen, I will also make a fuss to warn 
       ! the user
       if (.not.associated(vt_info(nv,igr)%vt_vector)) then
         write (unit=*,fmt='(a)') ' '
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') '! In subroutine vtable_edio_c (file var_tables_array.f90)                 !'
         write (unit=*,fmt='(a,1x,i4,1x,a,1x,i2,1x,a)')  &
                                  '! Vt_vector for variable',nv,'of grid',igr,'is not associated                !'
         write (unit=*,fmt='(a)') '! I will allocate it now.                                                 !'
         write (unit=*,fmt='(a)') '!-------------------------------------------------------------------------!'
         write (unit=*,fmt='(a)') ' '
         call vtable_edio_c(var,nv,igr,0,glob_id,var_len,var_len_global,max_ptrs,tabstr)
       end if
       
       vt_info(nv,igr)%nptrs = vt_info(nv,igr)%nptrs + 1
       iptr = vt_info(nv,igr)%nptrs
       
       vt_info(nv,igr)%vt_vector(iptr)%globid = glob_id
       vt_info(nv,igr)%vt_vector(iptr)%var_cp   => var
       vt_info(nv,igr)%vt_vector(iptr)%varlen = var_len

    end if
    
    
    return
  end subroutine vtable_edio_c

  ! =====================================================
  
  subroutine metadata_edio(nv,igr,lname,units,dimstr)
    
    
    implicit none
    
    integer :: t
    integer :: nv,igr
    character (len=*) :: lname
    character (len=*) :: units
    character (len=*) :: dimstr
    
    vt_info(nv,igr)%lname = trim(lname)
    vt_info(nv,igr)%units = trim(units)
    vt_info(nv,igr)%dimlab = trim(dimstr)
    
    return
  end subroutine metadata_edio
  
    




End Module var_tables_array
