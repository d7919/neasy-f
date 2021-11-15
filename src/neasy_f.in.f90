module neasyf
  use netcdf, only : NF90_INT
  implicit none

  private
  public :: neasyf_open, neasyf_close, neasyf_dim, neasyf_write, neasyf_read, neasyf_error

  integer, parameter :: nf_kind = kind(NF90_INT)

  interface neasyf_type
    module procedure neasyf_type_scalar
{mod_proc_neasyf_type_rank}   
  end interface neasyf_type

  interface neasyf_write
    module procedure neasyf_write_scalar
{mod_proc_neasyf_write_rank}
  end interface neasyf_write

  interface neasyf_read
    module procedure neasyf_read_scalar
{mod_proc_neasyf_read_rank}
  end interface neasyf_read

  interface polymorphic_put_var
    module procedure polymorphic_put_var_scalar
{mod_proc_polymorphic_put_var_rank}
  end interface polymorphic_put_var

  interface polymorphic_get_var
    module procedure polymorphic_get_var_scalar
{mod_proc_polymorphic_get_var_rank}
  end interface polymorphic_get_var

contains

  function neasyf_open(filename, action) result(ncid)
    use netcdf, only : nf90_open, nf90_create, NF90_NOWRITE, NF90_NETCDF4, NF90_CLOBBER, NF90_WRITE
    character(len=*), intent(in) :: filename
    character(len=*), intent(in) :: action
    integer(nf_kind) :: ncid
    integer :: status

    select case (action)
    case ('r')
      status = nf90_open(filename, NF90_NOWRITE, ncid)
    case ('rw')
      status = nf90_open(filename, ior(NF90_WRITE, NF90_NETCDF4), ncid)
    case ('w')
      status = nf90_create(filename, ior(NF90_CLOBBER, NF90_NETCDF4), ncid)
    case default
      error stop 'neasyf: Unsupported action ' // action
    end select
    call neasyf_error(status)
  end function neasyf_open

  subroutine neasyf_close(ncid)
    use netcdf, only : nf90_close
    integer, intent(in) :: ncid
    call neasyf_error(nf90_close(ncid), ncid)
  end subroutine neasyf_close

  function neasyf_type_scalar(variable) result(nf_type)
    use, intrinsic :: iso_fortran_env, only : int8, int16, int32, real32, real64
    use netcdf, only : NF90_BYTE, NF90_CHAR, NF90_SHORT, NF90_INT, NF90_REAL, NF90_DOUBLE
    integer(nf_kind) :: nf_type
    class(*), intent(in) :: variable

    select type (variable)
    type is (integer(int8))
      nf_type = NF90_BYTE
    type is (integer(int16))
      nf_type = NF90_SHORT
    type is (integer(int32))
      nf_type = NF90_INT
    type is (real(real32))
      nf_type = NF90_REAL
    type is (real(real64))
      nf_type = NF90_DOUBLE
    type is (character(len=*))
      nf_type = NF90_CHAR
    class default
      nf_type = -1
    end select
  end function neasyf_type_scalar

{neasyf_type_rank}

  function polymorphic_put_var_scalar(ncid, varid, values, start) result(status)
    use, intrinsic :: iso_fortran_env, only : int8, int16, int32, real32, real64
    use netcdf, only : nf90_put_var, NF90_EBADTYPE
    integer, intent(in) :: ncid, varid
    class(*), intent(in) :: values
    integer, dimension(:), optional, intent(in) :: start
    integer :: status
    select type (values)
    type is (integer(int8))
      status = nf90_put_var(ncid, varid, values, start)
    type is (integer(int16))
      status = nf90_put_var(ncid, varid, values, start)
    type is (integer(int32))
      status = nf90_put_var(ncid, varid, values, start)
    type is (real(real32))
      status = nf90_put_var(ncid, varid, values, start)
    type is (real(real64))
      status = nf90_put_var(ncid, varid, values, start)
    type is (character(len=*))
      status = nf90_put_var(ncid, varid, values, start)
    class default
      status = NF90_EBADTYPE
    end select
  end function polymorphic_put_var_scalar

{polymorphic_put_var_rank}

  function polymorphic_get_var_scalar(ncid, varid, values) result(status)
    use, intrinsic :: iso_fortran_env, only : int8, int16, int32, real32, real64
    use netcdf, only : nf90_get_var, NF90_EBADTYPE
    integer, intent(in) :: ncid, varid
    class(*), intent(out) :: values
    integer(nf_kind) :: status
    select type (values)
    type is (integer(int8))
      status = nf90_get_var(ncid, varid, values)
    type is (integer(int16))
      status = nf90_get_var(ncid, varid, values)
    type is (integer(int32))
      status = nf90_get_var(ncid, varid, values)
    type is (real(real32))
      status = nf90_get_var(ncid, varid, values)
    type is (real(real64))
      status = nf90_get_var(ncid, varid, values)
    type is (character(len=*))
      status = nf90_get_var(ncid, varid, values)
    class default
      status = NF90_EBADTYPE
    end select
  end function polymorphic_get_var_scalar

{polymorphic_get_var_rank}

  !> Create a dimension if it doesn't already exist.
  !>
  !> If the dimension doesn't exist, also create a variable of the same name and
  !> fill it with [[values]], or the integers in the range `1..dim_size`. The
  !> optional argument [[unlimited]] can be used to make this dimension
  !> unlimited in extent.
  !>
  !> Optional arguments "unit" and "description" allow you to create attributes
  !> of the same names.
  !>
  !> The netCDF IDs of the dimension and corresponding variable can be returned
  !> through [[dimid]] and [[varid]] respectively.
  subroutine neasyf_dim(parent_id, name, values, dim_size, dimid, varid, units, description, unlimited)
    use netcdf, only : nf90_inq_dimid, nf90_inq_varid, nf90_def_var, nf90_def_dim, nf90_put_var, nf90_put_att, &
         NF90_NOERR, NF90_EBADDIM, NF90_ENOTVAR, NF90_UNLIMITED
    !> Name of the variable
    character(len=*), intent(in) :: name
    !> NetCDF ID of the parent group/file
    integer, intent(in) :: parent_id
    !> Coordinate values
    class(*), dimension(:), optional, intent(in) :: values
    !> Size of the dimension if values isn't specified
    integer, optional, intent(in) :: dim_size
    !> NetCDF ID of the dimension
    integer, optional, intent(out) :: dimid
    !> NetCDF ID of the corresponding variable
    integer, optional, intent(out) :: varid
    !> Units of coordinate
    character(len=*), optional, intent(in) :: units
    !> Long description of coordinate
    character(len=*), optional, intent(in) :: description
    !> Is this dimension unlimited?
    logical, optional, intent(in) :: unlimited

    integer(nf_kind) :: nf_type
    integer :: status
    integer(nf_kind) :: dim_id, var_id
    integer :: i
    integer :: local_size
    integer, dimension(:), allocatable :: local_values

    if (present(values) .and. present(dim_size)) then
      error stop "Both 'values' and 'dim_size' given in 'neasyf_dim'. Only one must be present"
    end if

    status = nf90_inq_dimid(parent_id, name, dim_id)
    if (status == NF90_NOERR) then
      if (present(dimid)) then
        dimid = dim_id
      end if

      if (present(varid)) then
        call neasyf_error(nf90_inq_varid(parent_id, name, var_id))
        varid = var_id
      end if

      return
    end if

    if (status /= NF90_EBADDIM) then
      call neasyf_error(status, ncid=parent_id, dim=name, dimid=dim_id)
    end if

    ! Dimension doesn't exist, so let's create it
    if (present(values)) then
      local_size = size(values)
      nf_type = neasyf_type(values)
      ! TODO: check if nf_type indicates a derived type
    else if (present(dim_size)) then
      local_size = dim_size
      local_values = [(i, i=1, dim_size)]
      nf_type = neasyf_type(local_values)
    else
      error stop "Dimension does not exist and neither 'values' and 'dim_size' given in 'neasyf_dim'. Exactly one must be present"
    end if

    if (present(unlimited)) then
      if (unlimited) then
        local_size = NF90_UNLIMITED
      end if
    end if

    status = nf90_def_dim(parent_id, name, local_size, dim_id)
    call neasyf_error(status, dim=name, dimid=dim_id)

    status = nf90_def_var(parent_id, name, nf_type, dim_id, var_id)
    call neasyf_error(status, var=name, varid=var_id)

    if (present(units)) then
      status = nf90_put_att(parent_id, var_id, "units", units)
      call neasyf_error(status, var=name, varid=var_id, att="units")
    end if

    if (present(description)) then
      status = nf90_put_att(parent_id, var_id, "description", description)
      call neasyf_error(status, var=name, varid=var_id, att="description")
    end if

    if (present(dimid)) then
      dimid = dim_id
    end if

    if (present(varid)) then
      varid = var_id
    end if

    if (present(values)) then
      status = polymorphic_put_var(parent_id, var_id, values)
    else
      status = nf90_put_var(parent_id, var_id, local_values)
    end if
    call neasyf_error(status, parent_id, var=name, varid=dim_id)
  end subroutine neasyf_dim

  subroutine neasyf_write_scalar(parent_id, name, value_, units, description)
    use, intrinsic :: iso_fortran_env, only : int8, int16, int32, real32, real64
    use netcdf, only : nf90_inq_varid, nf90_def_var, nf90_put_var, nf90_put_att, &
         NF90_NOERR, NF90_ENOTVAR
    !> Name of the variable
    character(len=*), intent(in) :: name
    !> NetCDF ID of the parent group/file
    integer, intent(in) :: parent_id
    !> Value of the integer to write
    class(*), intent(in) :: value_
    !> Units of coordinate
    character(len=*), optional, intent(in) :: units
    !> Long description of coordinate
    character(len=*), optional, intent(in) :: description

    integer(nf_kind) :: nf_type
    integer :: status
    integer :: var_id

    status = nf90_inq_varid(parent_id, name, var_id)
    ! Variable doesn't exist, so let's create it
    if (status == NF90_ENOTVAR) then
      nf_type = neasyf_type(value_)
      ! TODO: check if nf_type indicates a derived type
      status = nf90_def_var(parent_id, name, nf_type, var_id)
      call neasyf_error(status, var=name, varid=var_id)

      if (present(units)) then
        status = nf90_put_att(parent_id, var_id, "units", units)
        call neasyf_error(status, var=name, varid=var_id, att="units")
      end if

      if (present(description)) then
        status = nf90_put_att(parent_id, var_id, "description", description)
        call neasyf_error(status, var=name, varid=var_id, att="description")
      end if
    else
      call neasyf_error(status, var=name, varid=var_id)
    end if

    status = polymorphic_put_var(parent_id, var_id, value_)
    call neasyf_error(status, parent_id, var=name, varid=var_id)
  end subroutine neasyf_write_scalar

{neasyf_write_rank}

  subroutine neasyf_read_scalar(parent_id, var_name, values)
    use netcdf, only : nf90_max_name, nf90_inq_varid, nf90_inquire_variable
    !> NetCDF ID of the parent file or group
    integer, intent(in) :: parent_id
    !> Name of the variable
    character(len=*), intent(in) :: var_name
    !> Storage for the variable
    class(*), intent(out) :: values

    integer :: status
    integer(nf_kind) :: file_var_id
    character(len=nf90_max_name) :: file_var_name

    status = nf90_inq_varid(parent_id, var_name, file_var_id)
    call neasyf_error(status, ncid=parent_id)

    status = polymorphic_get_var(parent_id, file_var_id, values)

    call neasyf_error(status, parent_id, varid=file_var_id, var=var_name)
  end subroutine neasyf_read_scalar

{neasyf_read_rank}

  !> Convert a netCDF error code to a nice error message. Writes to `stderr`
  !>
  !> All the arguments except `istatus` are optional and are used to give more
  !> detailed information about the error
  subroutine neasyf_error(istatus, ncid, varid, dimid, file, dim, var, att, message)
    use, intrinsic :: iso_fortran_env, only : error_unit
    use netcdf, only: NF90_GLOBAL, nf90_strerror, nf90_inquire_variable, nf90_inquire_dimension, NF90_NOERR
    implicit none
    !> The netCDF error code to convert to a message
    integer, intent (in) :: istatus
    !> netCDF ID of the file
    integer, intent (in), optional :: ncid
    !> netCDF ID of the variable
    integer, intent (in), optional :: varid
    !> netCDF ID of the dimension
    integer, intent (in), optional :: dimid
    !> Name of the file
    character (*), intent (in), optional :: file
    !> Name of the dimension
    character (*), intent (in), optional :: dim
    !> Name of the variable
    character (*), intent (in), optional :: var
    !> Name of the attribute
    character (*), intent (in), optional :: att
    !> Custom text to append to the error message
    character (*), intent (in), optional :: message
    integer :: ist
    character (20) :: varname, dimname

    if (istatus == NF90_NOERR) return

    write (error_unit, '(2a)', advance='no') 'ERROR: ', trim (nf90_strerror (istatus))

    if (present(file)) &
         write (error_unit, '(2a)', advance='no') ' in file ', trim (file)

    if (present(dim)) &
         write (error_unit, '(2a)', advance='no') ' in dimension ', trim (dim)

    if (present(var)) &
         write (error_unit, '(2a)', advance='no') ' in variable ', trim (var)

    if (present(varid)) then
       if (.not. present(ncid)) then
         error stop 'ERROR in netcdf_error: ncid missing while varid present in the argument'
       end if

       if (present(att) ) then
         if (varid == NF90_GLOBAL) then
           write (error_unit, '(2a)') ' in global attribute ', trim(att)
         else
           write (error_unit, '(2a)') ' with the attribute ', trim(att)
         end if
       else
         ist = nf90_inquire_variable (ncid, varid, varname)
         if (ist == NF90_NOERR) then
           write (error_unit, '(a,i8,2a)', advance='no') ' in varid: ', varid, &
                & ' variable name: ', trim (varname)
         else
           write (error_unit, *) ''
           write (error_unit, '(3a,i8,a,i8)', advance='no') 'ERROR in netcdf_error: ', &
                trim (nf90_strerror(ist)), ' in varid: ', varid, &
                ', ncid: ', ncid
         end if
       end if
    end if

    if (present(dimid)) then
       if (.not. present(ncid)) then
         error stop 'ERROR in netcdf_error: ncid missing while dimid present in the argument'
       end if

       ist = nf90_inquire_dimension (ncid, dimid, dimname)
       if (ist == NF90_NOERR) then
         write (error_unit, '(a,i8,2a)', advance='no') ' in dimid: ', dimid, &
              & ' dimension name: ', trim (dimname)
       else
         write (error_unit, *) ''
         write (error_unit, '(3a,i8,a,i8)', advance='no') 'ERROR in netcdf_error: ', &
              trim (nf90_strerror(ist)), ' in dimid: ', dimid, &
              ', ncid: ', ncid
       end if
    end if

    if (present(message)) write (error_unit, '(a)', advance='no') trim(message)

    ! append line-break
    write(error_unit,*)

    error stop "Aborted by netcdf_error"
  end subroutine neasyf_error
end module neasyf