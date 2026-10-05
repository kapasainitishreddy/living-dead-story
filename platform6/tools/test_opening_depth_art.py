#!/usr/bin/env python3
"""Original panorama geometry must not reintroduce angular self-closing sky ribbons."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
class PaintedSkyTests(unittest.TestCase):
    def test_cloud_brushes_have_smooth_closed_bezier_contours(self):
        tree=ET.parse(ROOT/'game/art/opening_depth/twilight_panorama.svg')
        clouds=[element for element in tree.iter() if element.get('fill')=='url(#cloud)']
        self.assertGreaterEqual(len(clouds),12)
        self.assertLessEqual(len(clouds),30)
        for cloud in clouds:
            contour=cloud.get('d','')
            self.assertGreaterEqual(contour.count('C'),4,'cloud contours must curve through both ends')
            self.assertTrue(contour.endswith(' Z'))
    def test_panorama_is_bounded_and_has_no_external_dependencies(self):
        path=ROOT/'game/art/opening_depth/twilight_panorama.svg'
        svg=path.read_text()
        root=ET.fromstring(svg)
        self.assertEqual((root.get('width'),root.get('height')),('2048','1024'))
        self.assertNotIn('http',svg.replace('http://www.w3.org/2000/svg',''))
        self.assertLess(path.stat().st_size,30000)
if __name__=='__main__': unittest.main()
