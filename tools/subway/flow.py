# ABOUTME: Median camera optical flow per frame of the subway clip, in a centre column where forward motion cancels out.
# ABOUTME: Usage: flow.py CLIP.ogv OUT.npy
import sys
import cv2
import numpy as np

cap = cv2.VideoCapture(sys.argv[1])
prev = None
rows = []
while True:
    ok, frame = cap.read()
    if not ok: break
    gray = cv2.cvtColor(cv2.resize(frame, (180, 180)), cv2.COLOR_BGR2GRAY)
    if prev is not None:
        flow = cv2.calcOpticalFlowFarneback(prev, gray, None, 0.5, 3, 15, 3, 5, 1.2, 0)
        top = flow[50:130, 60:120]  # centre column, where forward-motion expansion cancels out
        rows.append((np.median(top[..., 0]), np.median(top[..., 1])))
    prev = gray
np.save(sys.argv[2], np.array(rows))
print(len(rows), "frames")
