import unittest
from audit import footprint,pairs,validate
class AuditTests(unittest.TestCase):
 def test_dimensions(self):
  for bad in [[0,1],[-1,3],[True,1],[1,7],[1.5,2],None]:self.assertFalse(footprint(bad))
  self.assertTrue(footprint([2,4]))
 def test_duplicate_json(self):
  with self.assertRaises(ValueError):pairs([('ring',1),('ring',2)])
 def test_orientation_and_selection(self):
  b={'weapon':{'footprint':[3,1],'equipment_destination':'weapon'}}
  p={'selections':[{'asset_id':'a','kind':'equipment','game_id':'weapon','cells':[1,3]}]}
  self.assertEqual(len(validate(b,p)),2)
 def test_orphan(self):
  self.assertEqual(len(validate({}, {'selections':[{'asset_id':'a','kind':'equipment','game_id':'missing','cells':[1,1]}]})),1)
 def test_valid(self):
  self.assertEqual(validate({'ring':{'footprint':[1,1],'equipment_destination':'ring'}},{}),[])
if __name__=='__main__':unittest.main()
