from PIL import Image

img = Image.open('W:\MRI project\Data\Images\183043_slice_1.nii')

img_res = img.crop(0,0,256,192)

img_res.show()



