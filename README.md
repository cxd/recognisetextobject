#  Recognise Text Object

This example performs the following pipeline.

- capture video (AVKit)
- render video capture to display (AVKit)
- extract image buffer (CIImage)
- use the vision kit to detect character boundaries (Vision Kit)
- group character boxes into word segments (Vision Kit)
- generate batches of word boxes for OCR recognition using Tesseract
- use TTS voice to speak words generated one batch at a time. (AV Kit)

#### Other examples of tools

Previous examples of utilising each of these capabilities on iOS are available at:

- For using AVKit to capture video and additional notes on use of CoreML for digit recognition refer to:
        -   https://github.com/josephchang10/ImageClassificationwithVisionandCoreML

- For notes on using TesseractOCR on iOS refer to:
        -  https://www.raywenderlich.com/93276/implementing-tesseract-ocr-ios
        - https://github.com/gali8/Tesseract-OCR-iOS
        
- For notes on using the AVSpeechSynthesizer refer to the apple developer site.

## Project Description

This project is a short proof of concept of an assistive utility for use in cases where the end user may have difficulty reading due to partial sight.
The intention is to make use of readily available consumer products, in this case the iPhone and iOS related technology stack.

The audience would be for people who may have partial sight, but may require some assistance in reading signage.

## Limitations and areas for further exploration.

This is a very short duration investigation, not intended for production usage, however, there are a number of limitations that I can think of.

#### User interface screen dependency for low site.

The end user interface may not be entirely appropriate for someone with partial site, for exampe, using a rectangle to highlight an area of text or word on a video stream may be just as difficult to see for a person with partial site, as the original word is in front of them.
Hence limiting the device to read out only those words that the end user touches may pose some difficulty. More methods of interaction should
be investigated such as permitting the user to point using their hand in front of the camera and recognising the word closest to where they are pointing prior to reading that out.
How does a screen provide feedback, for a person of low site? Perhaps high contrast colours may be of some help here, and perhaps some kind of audible tone that assists in aiming at the target word either using touch motions or using the hand in front of the device tracked in the video stream.

#### Image Preprocessing

Lighting conditions are highly variable and pose a very big challenge, the optical character recognition provided by Tesseract OCR is superb
for what is available in open source, however much effort needs to go into preprocessing images in order to ensure they have a consistent form, contrast and colour prior to issuing to the API. This is an area worth further effort.

#### Comparative OCR technologies.

It may be interesting to look into comparative OCR capabilities, CoreML would also be of interest, although requires alot of training data for character recognition. The efforts required to obtain valid training set would be quite high, but the advantage would be in being able to fine tune the models.

Considering Tesseract OCR may have some capability to be updated with additional training data, it would be of value to determine the method of model evaluation used in that project, and to investigate the processes that would permit fine tuning OCR which in itself would be significant effort. But if this were a genuine production product, consideration to this end would be necessary to improve and tune performance, as well as to the previous point regarding light conditions.


#### Collection, feedback

Adding a mechanism to collect feedback about incorrect transcriptions along with the image that is captured for the transcription would be beneficial both in generating further training sets and in tuning cycles where fine tuning models can be done practically.
The storage, collection and manual transcription required for a production system would also be significant infrastructure but also would require due consideration.

### Further Comments

iOS provides a wide variety of tools available that could potentially be used to create accessibility aides that would be relatively affordable, and utilise widely available consumer hardware rather than specialised devices. There is certainly a great deal of potential for this area of technology, and I think accessibility in general can be broadly overlooked. Such tools are an area where a technology capability can contribute to improving the quality of life of its end users, for reasonable cost. It is interesting to consider this tyoe of application, and it would not be without significant challenges for design, technical capability and infrastructure to support this type of initiative, but such an application would be of benefit. There are a number of applications already emerging in this field, which give some optimism for the potential to apply widely available tools to the problem of accessibility.






