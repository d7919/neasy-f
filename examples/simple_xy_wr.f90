program simple_xy_wr
  use neasyf
  implicit none

  character (len = *), parameter :: FILE_NAME = "simple_xy_nc4.nc"
  character (len = *), parameter :: VAR_NAME = "data"
  integer, parameter :: NDIMS = 2
  integer, parameter :: NX = 6, NY = 12
  integer :: ncid, varid
  integer :: x_dimid, y_dimid
  integer :: data_out(NY, NX), data_in(NY, NX)
  integer :: x, y

  ! Create some pretend data. If this wasn't an example program, we
  ! would have some real data to write, for example, model output.
  do x = 1, NX
     do y = 1, NY
        data_out(y, x) = (x - 1) * NY + (y - 1)
     end do
  end do

  ncid = neasyf_open(FILE_NAME, "w")

  call neasyf_dim(ncid, "x", [(x, x=1, NX)], x_dimid)
  call neasyf_dim(ncid, "y", [(x, x=1, NY)], y_dimid)

  call neasyf_write(ncid, "data", data_out, [y_dimid, x_dimid], &
       units="Pa", description="Synthetic pressure")

  call neasyf_close(ncid)

  print *, '*** SUCCESS writing example file ', FILE_NAME, '!'

  ncid = neasyf_open(FILE_NAME, "r")

  call neasyf_read(ncid, VAR_NAME, data_in)

  ! Check the data.
  do x = 1, NX
     do y = 1, NY
        if (data_in(y, x) /= (x - 1) * NY + (y - 1)) then
           print *, "data_in(", y, ", ", x, ") = ", data_in(y, x)
           error stop "Data mismatch"
        end if
     end do
  end do

  ! Close the file, freeing all resources.
  call neasyf_close(ncid)

  print *,"*** SUCCESS reading example file ", FILE_NAME, "! "

end program simple_xy_wr
