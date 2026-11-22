import unittest
from reconcile import reconcile,routes,GAME,LIB
class ReconcileTests(unittest.TestCase):
 def fixture(self):return {k:{'footprint':v} for k,v in {'amulet':[1,1],'staff':[2,4],'wraps':[2,2],'slippers':[2,2]}.items()}
 def test_fallback(self):
  rows=reconcile(self.fixture(),{},[],{GAME+'assets/item_portraits/amulet.png'})
  self.assertEqual(rows[0]['finding'],'fallback_tracked_not_missing')
  self.assertEqual(rows[1]['finding'],'no_tracked_fallback')
  self.assertFalse(rows[0]['engine_load_verified'])
 def test_priority(self):self.assertEqual(routes('amulet',{'portraits':{'amulet':'res://selected.png'}})[0],'res://selected.png')
 def test_incompatible_staff(self):
  e={'asset_id':'quarter','type':'quarterstaff','cells':[1,4],'texture_path':'q.png','status':'candidate','runtime_enabled':False}
  rows=reconcile(self.fixture(),{},[e],{LIB+'q.png'})
  c=rows[1]['candidates'][0];self.assertFalse(c['footprint_matches']);self.assertEqual(c['selection'],'proposal_only');self.assertTrue(c['tracked_texture'])
 def test_no_cross_material_guess(self):
  rows=reconcile(self.fixture(),{},[{'type':'plate_gloves'}],set())
  self.assertEqual(rows[2]['candidates'],[])
if __name__=='__main__':unittest.main()
