#  Recognise Object

This example performs the following pipeline.

- capture video (AVKit)
- render video capture to display (AVKit)
- extract image buffer (CIImage)
- use the vision kit to detect character boundaries (Vision Kit)
- group character boxes into word segments (Vision Kit)
- generate batches of word boxes for OCR recognition using Tesseract
- use TTS voice to speak words generated one batch at a time. (AV Kit)

Online examples:

Previous examples of utilising each of these capabilities on iOS are available at:

- 




