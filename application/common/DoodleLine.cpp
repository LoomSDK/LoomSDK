

#include "loom/common/platform/platformTime.h"
#include "loom/common/core/stringTable.h"
#include "loom/script/loomscript.h"
#include "loom/common/core/performance.h"

#ifdef _TRY_BEGIN
   #undef _TRY_BEGIN
   #undef _CATCH_ALL
   #undef _CATCH_END
   #define _TRY_BEGIN {
   #define _CATCH_ALL 
   #define _CATCH_END }
#endif
#include "DoodleLine.h"

/*
//LOOM_GETSET_IMPLEMENTATION(DoodleScoreComputer, float, NumPoints);
//LOOM_GETSET_IMPLEMENTATION(DoodleScoreComputer, float, ScoringDistanceSquared);

DoodleScoreComputer::DoodleScoreComputer()
{
   numPoints = 0;
   pointScore = 0;
   scoringDistSquared = 400*400;
   masterPathLength = 0.0f;
   userPathLength = 0.0f;
   
}

float DoodleScoreComputer::minDistFromLineMaster(Point2F &pt)
{
   return minDistFromLine(pathMaster,pt);
}

float DoodleScoreComputer::minDistFromLine(utArray<Point2F> path, Point2F &pt)
{
   float minDist = 2000000.0f;
   if (path.size() == 1)
      return minDist;

   for (unsigned int i=1;i<path.size();i++)
   {
      float px = path[i-1].x - path[i].x;
      float py = path[i-1].y - path[i].y;
      float u = ((pt.x-path[i-1].x)*px + (pt.y-path[i-1].y)*py) / (px*px + py*py);
      if (u > 1.0f)
         u = 1.0f;
      else if (u < 0.0f)
         u = 0.0f;
      float x = path[i-1].x + u*px;
      float y = path[i-1].y + u*py;
      float dx = x - pt.x;
      float dy = y - pt.y;
      
      float dist = dx * dx + dy * dy;
      if (dist < minDist)
         minDist = dist;
   }
   
   return minDist;
}

float DoodleScoreComputer::masterFromUserDistAvgScore()
{
   float totalScore = 0;
   for (unsigned int i=0;i<pathMaster.size();i++)
   {
      float minDist = minDistFromLine(pathUser,pathMaster[i]);
      if (minDist > scoringDistSquared)
         minDist = scoringDistSquared;
      float score = 1.0f - minDist / scoringDistSquared;
      totalScore += (score * score);
   }
   
   return totalScore / pathMaster.size();
}

float DoodleScoreComputer::computeScore()
{
   // Compute a blended score based upon how far off each path is from the other
   float avgDistMasterScore = masterFromUserDistAvgScore();
   float avgDistUserScore = pointScore / numPoints;
   blendedScore = ((avgDistMasterScore*masterPathLength) + (avgDistUserScore*userPathLength)) / (masterPathLength+userPathLength);
   
   // Difference between the length of the path user drew compared to path user was supposed to follow
   float deltaDist = abs(1.0f - masterPathLength/userPathLength);
   if (deltaDist > 1.0f)
      deltaDist = 0.0f;
   else
      deltaDist = 1.0f - deltaDist;
   
   // This is a value between 0 and 1 (with 1 being best)
   blendedScore *= (deltaDist * deltaDist);
   
   pathScore = computePathScore();
   percentScore = blendedScore * 100;
   
   platform_debugOut("DoodleScene::computeScore() pathScore: %f , computedScore: %f pct: %f",pathScore, (pathScore*blendedScore + 0.5),percentScore);
   
   return (pathScore * blendedScore + 0.5f);
}

float DoodleScoreComputer::computeDot(Point2F pt1, Point2F pt2, Point2F pt3)
{
   float dx1 = pt2.x - pt1.x;
   float dy1 = pt2.y - pt1.y;
   float len1 = sqrt(dx1*dx1 + dy1*dy1);
   dx1 /= len1;
   dy1 /= len1;
   
   float dx2 = pt3.x - pt2.x;
   float dy2 = pt3.y - pt2.y;
   float len2 = sqrt(dx2*dx2 + dy2*dy2);
   dx2 /= len2;
   dy2 /= len2;
   
   return (dx1 * dx2 + dy1 * dy2);
}

float DoodleScoreComputer::computePathScore()
{
   float crookedness = 0.0f;
   
   // Compute how crooked our path is
   for (unsigned int i=1;i<pathMaster.size()-1;i++)
   {
      float dot = computeDot(pathMaster[i-1],pathMaster[i],pathMaster[i+1]);
      float crookToAdd = dot < 0.8f ? 0.8f : dot;
      crookToAdd = 1.0f - sqrt(sqrt(crookToAdd));
      crookedness += crookToAdd * 5.0f;
   }
   
   // I know "angledness" is not a word
   float angledness = 0.0f;
   for (unsigned int i=0;i<pathMaster.size()-1;i++)
   {
      float dx = pathMaster[i+1].x - pathMaster[i].x;
      float dy = pathMaster[i+1].y - pathMaster[i].y;
      float len = sqrt(dx*dx + dy*dy);
      dy /= len;
      float dot = dy * dy;
      float angleAmount = 0.5f - abs(0.5f-dot);
      angledness += angleAmount;
   }
   
   float avgAngle = angledness / (pathMaster.size()-1);
   float angAdjust = 1.0f + avgAngle / 2.0f;
   float levelScore = (masterPathLength / 4.0f) * (1.0f + crookedness) * angAdjust;
   
   platform_debugOut("crookedness: %f  angleness: %f  s: %f", crookedness, avgAngle, levelScore);
   
   return levelScore;
}

void DoodleScoreComputer::masterPathAdd(const Point2F& p)
{
   
   //platform_debugOut("DoodleScoreComputer::masterPathAdd(): %f,%f", p.x,p.y);
   pathMaster.push_back(p);
   masterPathLength = float(pathMaster.size());
   
}

void DoodleScoreComputer::userPathAdd(const Point2F& p)
{
   
   //platform_debugOut("DoodleScoreComputer::userPathAdd(): %f,%f", p.x,p.y);
   pathUser.push_back(p);
   userPathLength = float(pathUser.size());
}

void DoodleScoreComputer::masterPathClear()
{
   pathMaster.clear();
   masterPathLength = float(pathMaster.size());
}

void DoodleScoreComputer::userPathClear()
{
   pathMaster.clear();
   userPathLength = float(pathUser.size());
}

void DoodleScoreComputer::setScoringDistanceSquared(float s)
{
   scoringDistSquared = s;
}

float DoodleScoreComputer::getScoringDistanceSquared() const
{
   return scoringDistSquared;
}

void DoodleScoreComputer::setNumPoints(float n)
{
   numPoints = n;
}

float DoodleScoreComputer::getNumPoints() const
{
   return numPoints;
}

void DoodleScoreComputer::setUserPathLength(float l)
{
   userPathLength = l;
}

float DoodleScoreComputer::getUserPathLength() const
{
   return userPathLength;
}


void DoodleScoreComputer::setBlendedScore(float l)
{
   blendedScore = l;
}

float DoodleScoreComputer::getBlendedScore() const
{
   return blendedScore;
}

void DoodleScoreComputer::setPathScore(float l)
{
   pathScore = l;
}

float DoodleScoreComputer::getPathScore() const
{
   return pathScore;
}


void DoodleScoreComputer::setPercentScore(float l)
{
   percentScore = l;
}

float DoodleScoreComputer::getPercentScore() const
{
   return percentScore;
}

void DoodleScoreComputer::setPointScore(float l)
{
   pointScore = l;
}

float DoodleScoreComputer::getPointScore() const
{
   return pointScore;
}
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------

DoodleLine::DoodleLine(): lineTexture2d(NULL), splotchTexture2d(NULL), randGenerator(13),
   lineWidth(10), lineDirty(false), bevelRadius(3,3)
{
   randSeed = platform_getMilliseconds();
   lineGenerationWall = 0;
}

DoodleLine::~DoodleLine()
{
}

float DoodleLine::minDistFromLineMaster(Point2F &pt)
{
   return minDistFromLine(tessPath,pt);
}

float DoodleLine::minDistFromLine(utArray<Point2F> path, Point2F &pt)
{
   float minDist = 2000000.0f;
   if (path.size() == 1)
      return minDist;

   for (unsigned int i=1;i<path.size();i++)
   {
      float px = path[i-1].x - path[i].x;
      float py = path[i-1].y - path[i].y;
      float u = ((pt.x-path[i-1].x)*px + (pt.y-path[i-1].y)*py) / (px*px + py*py);
      if (u > 1.0f)
         u = 1.0f;
      else if (u < 0.0f)
         u = 0.0f;
      float x = path[i-1].x + u*px;
      float y = path[i-1].y + u*py;
      float dx = x - pt.x;
      float dy = y - pt.y;
      
      float dist = dx * dx + dy * dy;
      if (dist < minDist)
         minDist = dist;
   }
   
   return minDist;
}

void DoodleLine::addPoint(const Point2F& p, const ColorF& c)
{
   //platform_debugOut("DoodleLine::addPoint(): %f,%f / %f, %f, %f, %f", p.x,p.y,c.r,c.g,c.b,c.a);

   linePoints.push_back(p);
   lineColors.push_back(c);
   lineDirty = true;
}

void DoodleLine::setLastPoint(const Point2F& p, const ColorF& c)
{
   linePoints[linePoints.size() - 1] = p;
   lineColors[linePoints.size() - 1] = c;
   lineDirty = true;
}

void DoodleLine::clear()
{
   
   linePoints.clear(true);
   lineColors.clear(true);
   
   uvs.clear(true);
   quads.clear(true);
   
   underSplotchQuads.clear(true);
   splotchQuads.clear(true);

   pointsSpline.clear();
   colorsSpline.clear();
   
   vertCount = 0;
   randSeed = platform_getMilliseconds();
   lineDirty = true;
   lineGenerationWall = 0;
}

Point2F DoodleLine::evaluatePoint(float t)
{
   // call tesselate to make sure the spline is generated
   tesselateLine();

   return pointsSpline.evaluate(t);
}

float DoodleLine::getSplineLength()
{
   // call tesselate to make sure the spline is generated
   tesselateLine();

   return pointsSpline.getLength();
}

void DoodleLine::setLineWidth(float n)
{
   platform_debugOut("Setting line width to %f", n);
   lineWidth = n;
   lineDirty = true;
}

float DoodleLine::getLineWidth() const
{
   return lineWidth;
}

void DoodleLine::setBeveled(bool b)
{
   beveled = b;
   lineDirty = true;
}

bool DoodleLine::getBeveled() const
{
   return beveled;
}

void DoodleLine::setTexture( const char *texName )
{
   texture = stringtable_insert(texName);
   lineTexture2d = CCTextureCache::sharedTextureCache()->addImage(texName);
   lineDirty = true;
}

StringTableEntry DoodleLine::getTexture()
{
   return texture;
}

void DoodleLine::setSplotchTexture( const char *texName )
{
   splotchTexture = stringtable_insert(texName);
   splotchTexture2d = CCTextureCache::sharedTextureCache()->addImage(texName);
   lineDirty = true;
}

StringTableEntry DoodleLine::getSplotchTexture()
{
   return splotchTexture;
}


void DoodleLine::calculateSplotchUVs(Point2F& ll, Point2F& lr, Point2F& ul, Point2F& ur, int idx)
{
   int numCellsInGrid = 4;
   int columns = (int)sqrtf((float)numCellsInGrid);
   int rows = columns;
   int row = idx/columns;
   int col = idx - row*rows;
   float slotDim = 1.0f/columns;
   float baseU = col*slotDim;
   float baseV = row*slotDim;
   
   ll.x = baseU;
   ll.y = baseV; 
   
   lr.x = baseU + slotDim;
   lr.y = baseV;
   
   ul.x = baseU;
   ul.y = baseV + slotDim;
   
   ur.x = baseU + slotDim;
   ur.y = baseV + slotDim;
   
}

void DoodleLine::calculateUVs(Point2F& ll, Point2F& ur, bool firstPoint, bool lastPoint)
{
   // For now always assume we are doing multi pass and that we are using
   // the first column of the texture.  The pass logic will offset the columns
   
   float pinchIn = 0.00;
   ll.x = 0.0f + pinchIn;
   ll.y = 0.5f; 
   ur.x = 1.0f/3 - pinchIn;
   ur.y = 0.5f;
   
   if(firstPoint)
   {
      //First quad
      ll.x = 0.0f;
      ll.y = 0.0f; 
      ur.x = 1.0f/3;
      ur.y = 0.415f;//Actual end is .414
      
   }
   else if(lastPoint)
   {
      //Last quad
      ll.x = 0.0f;
      ll.y = 0.52f; 
      ur.x = 1.0f/3;
      ur.y = 1.0f;
   }
}

void DoodleLine::createSplotchQuad(Splotch& splotch, utArray<doodleline_vert_t>& vertContainer)
{
   
   Point2F ul, ur, ll, lr, urUV, ulUV, llUV, lrUV;
   Point2F side = splotch.dir.tangent() * splotch.size;
   Point2F fwd = splotch.dir * splotch.size;
   
   ll = splotch.position - side - fwd;
   lr = splotch.position + side - fwd;
   ul = splotch.position - side + fwd;
   ur = splotch.position + side + fwd;
   
   calculateSplotchUVs(llUV,lrUV,ulUV,urUV,splotch.textureCell);
   
   doodleline_vert_t vert;
   
   copyIntoGfxVert(vert, ll, splotch.color, llUV);
   vertContainer.push_back(vert);
   
   copyIntoGfxVert(vert, lr, splotch.color, lrUV);
   vertContainer.push_back(vert);
   
   copyIntoGfxVert(vert, ur, splotch.color, urUV);
   vertContainer.push_back(vert);
   
   copyIntoGfxVert(vert, ll, splotch.color, llUV);
   vertContainer.push_back(vert);
   
   copyIntoGfxVert(vert, ur, splotch.color, urUV);
   vertContainer.push_back(vert);
   
   copyIntoGfxVert(vert, ul, splotch.color, ulUV);
   vertContainer.push_back(vert);
}

void DoodleLine::expandCap(Point2F& ll, Point2F& lr, Point2F& ul, Point2F& ur, bool contract)
{
   Point2F lengthVec = ur - lr;
   float length = lengthVec.getMagnitude();
   float lengthAdjust = lineWidth - length;   
   
   Point2F adjustVec = lengthVec;
   adjustVec.setMagnitude(lengthAdjust*1.25f);
   
   if(contract)
   {
      ll -= adjustVec;
      lr -= adjustVec;
   }
   else 
   {
      ul += adjustVec;
      ur += adjustVec;
   }
   
   
}

void DoodleLine::buildMesh()
{
   // Wipe splotches.
//   underSplotches.clear(true);
//   splotches.clear(true);

   // Clear out line.
//   quads.clear(true);
//   uvs.clear(true);
   
   int numPoints = (int)linePoints.size();
   Point2F lastUL, lastUR, dir, p3;
   
   //randGenerator.setSeed(randSeed);
   
   formerLastUL.resize(numPoints);
   formerLastUR.resize(numPoints);
   
   const int retesselateWindow = 4;
   
   if(lineGenerationWall > 0)
   {
      // Recover old lastUL and lastUR.
      lastUL = formerLastUL[lineGenerationWall - 1];
      lastUR = formerLastUR[lineGenerationWall - 1];
   }

   tessPath.clear();

   for(int i = lineGenerationWall; i < numPoints - 1; i++)
   {
      const bool lastPoint = !(i < numPoints - 2);
      const bool firstPoint = i == 0;
      
      const Point2F &p1 = linePoints[i];
      const ColorF  &lc = lineColors[i];
      
      const Point2F &p2 = linePoints[i+1];
      const ColorF  &uc = lineColors[i+1];
            
      if (i == 0)
         tessPath.push_back(p1);
      tessPath.push_back(p2);

      dir = p2 - p1;
      dir.normalize();
      Point2F p3 =  p2 + dir;
      if(lastPoint == false)
      {
         p3 = linePoints[i+2];
      }
      
      // TODO: We should be doing a better job of smoothing out sharp turns
      // for now we will only apply this to the master line so it doesn't look
      // so weird in certain doodles
      bool sharpTurn = beveled;
      
      // See if we should drop a splotch. Only drop splotches for points
      // that are not goin to be retesselated.
      // if(i < numPoints - retesselateWindow)
      // {         
      //    //check for discontinuity
      //    Point2F d2 = p3 - p2;
      //    d2.normalize();
      //    Point2F d1 = p1 - p2;
      //    d1.normalize();
      //    float dot = d1.x*d2.x + d1.y*d2.y;

      //    bool forceSplotch = false;
      //    if(lastPoint == false)
      //       forceSplotch = randGenerator.randUnit() < 0.025f;

      //    if((dot > -0.5 || forceSplotch) && !lastPoint)
      //    {
      //       Point2F splotchDir = p3 - p1;
      //       splotchDir.normalize();
      //       sharpTurn = true;

      //       Splotch s;
      //       s.position = p2;
      //       s.dir = splotchDir;
      //       s.color = lc;
      //       float size = randGenerator.randRangeInt(48, 64);
      //       s.size = Point2F(size,size);
      //       s.textureCell = randGenerator.randRangeInt(1, 3);

      //       splotches.push_back(s);
      //    }

      //    if(firstPoint || lastPoint)
      //    {
      //       Splotch s;
      //       s.position = firstPoint?p1:p2;
      //       s.dir = dir;
      //       s.color = firstPoint?lc:uc;

      //       s.size = Point2F(lineWidth*0.5f,lineWidth*0.5f);
      //       s.textureCell = 0;
      //       underSplotches.push_back(s);
      //    } 
      // } 

      generateQuads(i, p1,p2,p3,lc,uc,dir,firstPoint,lastPoint, lastUL, lastUR, sharpTurn);
      
      formerLastUL[i] = lastUL;
      formerLastUR[i] = lastUR;
   }
   
   lineGenerationWall = numPoints - retesselateWindow;
   if(lineGenerationWall < 0)
      lineGenerationWall = 0;
}

void DoodleLine::buildSplineMesh()
{
   quads.clear(true);
   quads.reserve(8192);
   uvs.clear(true);
   uvs.reserve(8192);
   
   float arcLength = pointsSpline.getLength();
   float segmentLength = 24.0f;
   float numPoints = arcLength/segmentLength;
   float coarseParamInc = 1/numPoints;
   
   // for subdividing the mesh where there is high curvature
   float subdivisions = 4.0f;
   float fineParamInc = 1/(numPoints*subdivisions);
   
   Point2F lastUL, lastUR;
   int lineTesselationCounter = 0;

   tessPath.clear();
   
   for(int i = 0; i < numPoints - 1; i++)
   {
      bool lastPoint = !(i < numPoints - 2);
      bool secondToLastPoint = !(i < numPoints - 3);
      bool firstPoint = i == 0;
      
      float baseParamT1 = i/(float)(numPoints);
      float baseParamT2 = (i+1)/(float)(numPoints);
      
      Point2F curvatureAt1 = pointsSpline.secondDeriv(baseParamT1);
      Point2F curvatureAt2 = secondToLastPoint? curvatureAt1 : pointsSpline.secondDeriv(baseParamT2);
      
      int numSubdivisions = 1;
      float tOffset = coarseParamInc;
      bool subdivided = false;
      
      if((curvatureAt1.getSquareMagnitude() > 50.0f || curvatureAt2.getSquareMagnitude() > 50.0f) && !firstPoint && !lastPoint)
      {
         // curve is changing fast.  subdivide
         numSubdivisions = (int)subdivisions;
         tOffset = fineParamInc;
         subdivided = true;
      }
      
      for(int j = 0; j < numSubdivisions; j++)
      {
         float splineT1 = baseParamT1 + j*tOffset;
         float splineT2 = baseParamT1 + (j+1)*tOffset;
         float splineT3 = baseParamT1 + (j+2)*tOffset;

         Point2F p1 = pointsSpline.evaluate(splineT1);
         Point2F p2 = pointsSpline.evaluate(splineT2);
         ColorF lc = colorsSpline.evaluate(splineT1);
         ColorF uc = colorsSpline.evaluate(splineT2);
      
         if (lineTesselationCounter == 0)
            tessPath.push_back(p1);
         tessPath.push_back(p2);

         Point2F p3 = pointsSpline.evaluate(splineT3);
         
         Point2F dir = p2 - p1;
         dir.normalize();
         if(lastPoint)
         {
            p3 = p2 + dir;
         }
         
         generateQuads(lineTesselationCounter++, p1,p2,p3,lc,uc,dir,firstPoint,lastPoint, lastUL, lastUR, false);
      }
   }
}
      
void DoodleLine::generateQuads(int offset, const Point2F& p1, const Point2F& p2, const Point2F& p3, const ColorF &lc,
                               const ColorF &uc, const Point2F& dir, bool firstPoint, 
                               bool lastPoint, Point2F& lastUL, Point2F& lastUR,
                               bool sharpTurn)
{
   float r = lineWidth*0.5f;
   
   // lside = lower side is the starting side/perpendicular/normal
   // uside = upper side is the ending side/perpendicular/normal
   Point2F lside,uside,lsideDir,usideDir,nextSide, nextSideDir;
   lside.x = dir.y*r;
   lside.y = -dir.x*r;
   lsideDir.x = dir.y;
   lsideDir.y = -dir.x;
   
   Point2F llUV,lrUV, ulUV, urUV, taUV, t0UV,t1UV,t2UV;
   
   calculateUVs(llUV,urUV,firstPoint,lastPoint);
    lrUV.x = urUV.x;
    lrUV.y = llUV.y;
    ulUV.x = llUV.x;
    ulUV.y = urUV.y;
   
   // calculate the staring/lower points of the "quad"
   Point2F ll, lr, ul, ur, nextl, nextr, t1,t2,t0,ta;
   if(firstPoint == false && !sharpTurn)
   {
      ll = lastUL;
      lr = lastUR;
   }
   else
   {
      ll = p1 - lside;
      lr = p1 + lside;
   }
   
   ul = p2 - lside;
   ur = p2 + lside;
   
   if(lastPoint == false && !sharpTurn)
   {
      // The ending side/perp/normal isn't the same as the start
      // it is based upon the next segments direction.
      // Side direction is different at each point
      Point2F dir2;
      dir2 = p3 - p2;
      dir2.normalize();
      
      uside.x = dir2.y*r;
      uside.y = -dir2.x*r;
      usideDir.x = dir2.y;
      usideDir.y = -dir2.x;
      
   } 
   else 
   {
      //Extrapolate p3 so later calculations don't need special cases
      uside = lside;
      usideDir = lsideDir;
   }
   
   nextSide = uside;
   nextSideDir = usideDir;
   
   nextl = p2 - nextSideDir*r;
   nextr = p2 + nextSideDir*r;
   
   Point2F interpl, interpr,interpdir, interpSideDir;
   interpl = (ul + nextl) * 0.5f;
   interpdir = p2 - ul;
   interpdir.normalize();
   
   
   interpl = p2 - interpdir*r;
   interpr = p2 + interpdir*r;
   
   ///////////////////////////////////////////////////////////////////////
   //       CHAMFERING                                                  //
   ///////////////////////////////////////////////////////////////////////
   //find out which direction we are turning for tween points      
   Point2F diff2, dir2, dir3;
   diff2 = p3 - p2;
   dir2 = diff2;
   dir2.normalize();
   
   bool curvingUp = true;
   float dot = lsideDir.x*dir2.x + lsideDir.y*dir2.y;
   if(dot <= 0)
   {
      curvingUp = false;
      ul = interpl;
      
      ta = ul;
      t0 = ur;
      
      taUV = ulUV;
      t0UV = urUV;
      t1UV = urUV;
      t2UV = urUV;
      
      t2 = ta + usideDir*2*r;
      
      lastUL= ta;
      lastUR= t2;
      
   }
   else 
   {
      curvingUp = true;
      
      ur = interpr;
      
      ta = ur;
      t0 = ul;
      
      taUV = urUV;
      t0UV = ulUV;
      t1UV = ulUV;
      t2UV = ulUV;
      
      t2 = ta - usideDir*2*r;
      
      lastUL= t2;
      lastUR= ta;
   }
   
   if(sharpTurn)
   {
      t1 = t2 = t0;
      if(curvingUp)
      {
         lastUR = ta;
         lastUL = t0;
      }
      else 
      {
         lastUR = t0;
         lastUL = ta;
      }
   }
   
   
   Point2F middleNorm;
   middleNorm = (t0 + t2)*0.5;
   middleNorm = middleNorm - ta;
   middleNorm.normalize();
   
   t1 = ta + middleNorm*2*r;
    
   
   if(beveled &&  (lastPoint || firstPoint))
   {
      expandCap(ll,lr, ul, ur, firstPoint);
   }
   
   // Vertex emission. Always two quads, so 12 verts.   
   int curOffset = offset * 12;
   if(quads.size() < UTsize(curOffset) + 12)
   {
      quads.resize(curOffset + 12);
      uvs.resize(curOffset + 12);
   }
   
#define EMIT_VERT(a, b, c) \
   copyIntoGfxVert(quads[curOffset], a, b, c); uvs[curOffset] = c; curOffset++;

   // Base of line.
   EMIT_VERT(ll, lc, llUV);
   EMIT_VERT(lr, lc, lrUV);
   EMIT_VERT(ur, uc, urUV);
   EMIT_VERT(ll, lc, llUV);
   EMIT_VERT(ur, uc, urUV);
   EMIT_VERT(ul, uc, ulUV);
   
   // Chamfer tris.
   EMIT_VERT(ta, uc, taUV);
   EMIT_VERT(curvingUp?t0:t1, uc, curvingUp?t0UV:t1UV);
   EMIT_VERT(curvingUp?t1:t0, uc, curvingUp?t1UV:t0UV);
   EMIT_VERT(ta, uc, taUV);
   EMIT_VERT(curvingUp?t1:t2, uc, curvingUp?t1UV:t2UV);
   EMIT_VERT(curvingUp?t2:t1, uc, curvingUp?t2UV:t1UV);
   
#undef EMIT_VERT
}

void DoodleLine::createSplotches()
{
   splotchQuads.clear(true);
   for(int i = 0; i < (int)splotches.size(); i++)
   {
      createSplotchQuad(splotches[i],splotchQuads);
   }
   
   underSplotchQuads.clear(true);
   for(int i = 0; i < (int)underSplotches.size(); i++)
   {
      createSplotchQuad(underSplotches[i],underSplotchQuads);
   }
}

void drawVertexArray(const utArray<doodleline_vert_t> &verts)
{
   ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords | kCCVertexAttribFlag_Color );
   glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, sizeof(doodleline_vert_t), &verts[0].x);
   glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(doodleline_vert_t), &verts[0].r);
   glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(doodleline_vert_t), &verts[0].u);
  
   glDrawArrays(GL_TRIANGLES, 0, verts.size());
   CC_INCREMENT_GL_DRAWS(1);
}

void DoodleLine::tesselateLine()
{
   // Update the mesh if we're dirty.
   if(lineDirty && linePoints.size() > 1)
   {
      profilerBlock_t tessBlock = { "DoodleLine_tesselate", platform_getMilliseconds(), 2 };

      pointsSpline.setup(linePoints);
      colorsSpline.setup(lineColors);
      if(isSpline && linePoints.size() > 3)
      {
         buildSplineMesh();
      }
      else
      {
         buildMesh();
         createSplotches();
      }

      lineDirty = false;
      
      finishProfilerBlock(&tessBlock);
   }
}

void DoodleLine::draw()
{
   int numPoints = (int)linePoints.size();
   if(numPoints < 2)
      return;
   
   profilerBlock_t tessBlock = { "DoodleLine_tess", platform_getMilliseconds(), 2 };
   
   tesselateLine();

   finishProfilerBlock(&tessBlock);
   
   profilerBlock_t drawBlock = { "DoodleLine_draw", platform_getMilliseconds(), 4 };

   // Set up and draw the under spotches.
   setShaderProgram(CCShaderCache::sharedShaderCache()->programForKey(kCCShader_PositionTextureColorAlphaTest));
   getShaderProgram()->use();
   getShaderProgram()->setUniformForModelViewProjectionMatrix();

   CC_NODE_DRAW_SETUP();

   ccGLEnable(CC_GL_BLEND);
   ccGLBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);

   if(underSplotches.size() && false)
   {
      ccGLBindTexture2D(splotchTexture2d->getName());
      drawVertexArray(underSplotchQuads);      
   }

   ccGLBindTexture2D(lineTexture2d->getName());

   if(beveled && false)
   {
      for(int pass = 0; pass < 3; pass++)
      {
         float uInc = 0.33f;
         
         if(pass == 0)
            uInc = 0.0f;
         else if( pass == 1)
            uInc = 0.333f;
         else
            uInc = 0.667f;
         
         for(int vertIDX = 0; vertIDX < (int)quads.size(); vertIDX++)
         {
            Point2F uvBase = uvs[vertIDX];
            quads[vertIDX].u = uvBase.x + uInc;
         }
         
         drawVertexArray(quads);
      }
   }
   else // Not beveled just set the colors and draw once
   {
      drawVertexArray(quads);
   }
   
   // Draw the over splotches.
   if(splotchQuads.size() && false)
   {
      ccGLBindTexture2D(splotchTexture2d->getName());
      drawVertexArray(splotchQuads);      
   }
   
   // Clean up a bit.
   ccGLBindTexture2D(0);
   setShaderProgram(NULL);
   
   finishProfilerBlock(&drawBlock);
}

//------------------------------------------------------------------------------
using namespace LS;

int registerDoodleTypes(lua_State* L) 
{
   beginPackage(L, "DoubleDoodle")

   //GW .deriveClass<DoodleLine, cocos2d::CCNode> ("DoodleLine")
   .addConstructor <void (*)(void) >()
   .addVarAccessor("lineWidth", &DoodleLine::getLineWidth, &DoodleLine::setLineWidth)
   .addVarAccessor("beveled", &DoodleLine::getBeveled, &DoodleLine::setBeveled)
   .addVar("isSpline", &DoodleLine::isSpline)
   .addMethod("minDistFromLineMaster", &DoodleLine::minDistFromLineMaster)
   .addMethod("addPoint", &DoodleLine::addPoint)
   .addMethod("setLastPoint", &DoodleLine::setLastPoint)
   .addMethod("clear", &DoodleLine::clear)
   .addMethod("setTexture", &DoodleLine::setTexture)
   .addMethod("getTexture", &DoodleLine::getTexture)
   .addMethod("setSplotchTexture", &DoodleLine::setSplotchTexture)
   .addMethod("getSplotchTexture", &DoodleLine::getSplotchTexture)
   .addMethod("evaluatePoint", &DoodleLine::evaluatePoint)
   .addMethod("getSplineLength", &DoodleLine::getSplineLength)
   .endClass()
      
   .beginClass<DoodleScoreComputer> ("DoodleScore")
   .addConstructor <void (*)(void) >()
   .addVarAccessor("userPathLength", &DoodleScoreComputer::getUserPathLength, &DoodleScoreComputer::setUserPathLength)
   .addVarAccessor("numPoints", &DoodleScoreComputer::getNumPoints, &DoodleScoreComputer::setNumPoints)
   .addVarAccessor("scoringDistanceSquared",&DoodleScoreComputer::getScoringDistanceSquared, &DoodleScoreComputer::setScoringDistanceSquared)
   .addVarAccessor("blendedScore", &DoodleScoreComputer::getBlendedScore, &DoodleScoreComputer::setBlendedScore)
   .addVarAccessor("percentScore", &DoodleScoreComputer::getPercentScore, &DoodleScoreComputer::setPercentScore)
   .addVarAccessor("pathScore", &DoodleScoreComputer::getPathScore, &DoodleScoreComputer::setPathScore)
   .addVarAccessor("pointScore", &DoodleScoreComputer::getPointScore, &DoodleScoreComputer::setPointScore)
   .addMethod("minDistFromLineMaster", &DoodleScoreComputer::minDistFromLineMaster)
   .addMethod("computeScoreNative", &DoodleScoreComputer::computeScore)
   .addMethod("computePathScore", &DoodleScoreComputer::computePathScore)
   .addMethod("masterPathAdd", &DoodleScoreComputer::masterPathAdd)
   .addMethod("userPathAdd", &DoodleScoreComputer::userPathAdd)
   .addMethod("masterPathClear", &DoodleScoreComputer::masterPathClear)
   .addMethod("userPathClear", &DoodleScoreComputer::userPathClear)
   .endClass()

   .endPackage();

   return 0;

}
*/