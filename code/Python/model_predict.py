import ants
import antspynet

import os
os.environ["CUDA_VISIBLE_DEVICES"] = "0"
import glob
import shutil

import random
import math
import numpy as np

import tensorflow as tf
import tensorflow.keras as keras
import tensorflow.keras.backend as K

K.clear_session()
gpus = tf.config.experimental.list_physical_devices("GPU")
if len(gpus) > 0:
    tf.config.experimental.set_memory_growth(gpus[0], True)

tf.compat.v1.disable_eager_execution()

base_directory = '/home/frawleyts/'
scripts_directory = base_directory + 'Scripts/'

from batch_generator import batch_generator

template_size = (256, 256)
classes = (0, 1)

################################################
#
#  Create the model and load weights
#
################################################

number_of_classification_labels = len(classes)
image_modalities = ["Hist"]
channel_size = len(image_modalities)


predictionImageFiles = glob.glob(base_directory + "Prediction/*.nii.gz")

predictionImage = ants.image_read( predictionImageFiles[1])   
predictionData = np.zeros(( len( predictionImageFiles ), *template_size, 1 ))

for i in range(0,len(predictionImageFiles)):
  predictionImage = ants.image_read( predictionImageFiles[i])
  predictionImage = predictionImage / predictionImage.max()   
  predictionArray = predictionImage.numpy()
  predicitonArray = (predicitonArray - predicitonArray.min()) / (predicitonArray.max() - predicitonArray.min())
  predictionData[i,:,:,0] = predictionArray

X_prediction = predictionData

unet_model = antspynet.create_unet_model_2d((*template_size, channel_size),
   number_of_outputs=1, mode="sigmoid", number_of_filters=(64, 96, 128, 256, 512),
   convolution_kernel_size=(3, 3), deconvolution_kernel_size=(2, 2),
   dropout_rate=0.0, weight_decay=0, 
   additional_options=("initialConvolutionKernelSize[5]", "attentionGating"))

weights_filename = scripts_directory + "weibinWeights.h5"
if os.path.exists(weights_filename):
    unet_model.load_weights(weights_filename)

unet_loss = antspynet.binary_dice_coefficient(smoothing_factor=0.)

unet_model.compile(optimizer=keras.optimizers.Adam(lr=2e-4),
                   loss=unet_loss,
                   metrics=[unet_loss])

predictedData = unet_model.predict( X_prediction, verbose = 1 )

for i in range(0,len(predictionImageFiles)):
  for j in range(0,channel_size) :
    imageArray = predictedData[i,:,:,j]  
    image = predictionImage.new_image_like(imageArray)

    imageFileName = predictionImageFiles[i].replace( ".nii.gz", ( "_Probability" + j + ".nii.gz" ))
    imageFileName = imageFileName.replace(base_directory + "Prediction/", base_directory + "Output/")
    imageFileName = imageFileName.replace( 'Images/', '')

    ants.image_write( image, imageFileName ) 
 

