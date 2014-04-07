#ifndef _DOODLELINE_H_
#define _DOODLELINE_H_

//#include "loom/common/core/stringTable.h"
//#include "loom/common/utils/utTypes.h"
//#include "loom/common/utils/utRandom.h"
//#include "catmullRom.h"

#ifdef _NO_LOCALES
#undef _NO_LOCALES
#endif
#define _NO_LOCALES 1

/*
struct doodleline_vert_t
{
   float x,y,z;      // 12 bytes
   GLubyte r,g,b,a;  // 4 bytes
   float u,v;        // 8 bytes
   //24 bytes total.
};

int registerDoodleTypes(lua_State* L);

// This is not the right place for any of this logic.  It is only going here
// temporarily because it is the easiest place for me to put native code and 
// bind it to script.
class DoodleScoreComputer
{
public:
   DoodleScoreComputer();
   
   float numPoints;
   float pointScore;
   float scoringDistSquared;
   
   // Path to follow
   utArray<Point2F>     pathMaster;
   float                masterPathLength;
   
   // Path the user has drawn
   utArray<Point2F>     pathUser;
   float                userPathLength;

   // Path used when measuring distance
   utArray<Point2F>     pathReference;
   
   float blendedScore;
   float pathScore;
   float percentScore;
   
   float minDistFromLineMaster(Point2F &pt);
   float minDistFromLine(utArray<Point2F> path, Point2F &pt);
   float masterFromUserDistAvgScore();
   float computeScore();
   float computeDot(Point2F pt1, Point2F pt2, Point2F pt3);
   float computePathScore();
   
   void masterPathAdd(const Point2F& p);
   void userPathAdd(const Point2F& p);
   void masterPathClear();
   void userPathClear();
   void setScoringDistanceSquared(float s);
   float getScoringDistanceSquared() const;
   void setNumPoints(float n);
   float getNumPoints() const;
   void setUserPathLength(float n);
   float getUserPathLength() const;
   void setBlendedScore(float n);
   float getBlendedScore() const;
   void setPercentScore(float n);
   float getPercentScore() const;
   void setPathScore(float n);
   float getPathScore() const;
   void setPointScore(float n);
   float getPointScore() const;

};

class DoodleLine //GW : public cocos2d::CCNode
{
public:
   struct Splotch
   {
      Point2F  position;
      Point2F  size;
      Point2F  dir;
      ColorF   color;
      int      textureCell;
   };
      
   DoodleLine();
   virtual ~DoodleLine();
      
   float minDistFromLineMaster(Point2F &pt);
   float minDistFromLine(utArray<Point2F> path, Point2F &pt);

   void addPoint(const Point2F& p, const ColorF& c);
   void setLastPoint(const Point2F& p, const ColorF& c);
   void clear();
   void setLineWidth(float l);
   float getLineWidth() const;
   void setBeveled(bool b);
   bool getBeveled() const;
   
   void setTexture(const char *texName);
   StringTableEntry getTexture();
   void setSplotchTexture(const char *texName);
   StringTableEntry getSplotchTexture();

   float getSplineLength();

   Point2F evaluatePoint(float t);
   
   cocos2d::CCTexture2D *lineTexture2d, *splotchTexture2d;

   void draw();
      
protected:
   void calculateSplotchUVs(Point2F& ll, Point2F& lr, Point2F& ul, Point2F& ur, int idx);
   void calculateUVs(Point2F& ll, Point2F& ur, bool firstPoint, bool lastPoint);
   void expandCap(Point2F& ll, Point2F& lr, Point2F& ul, Point2F& ur, bool contract);
   void createSplotchQuad(Splotch& splotch, utArray<doodleline_vert_t>& vertContainer);
   
   void buildMesh();
   void buildSplineMesh();
   void createSplotches();

   void tesselateLine();
   
   void generateQuads(int offset, const Point2F& p1, const Point2F& p2, const Point2F& p3, const ColorF &lc,
                      const ColorF &uc, const Point2F& dir, bool firstPoint, 
                      bool lastPoint, Point2F& lastUL, Point2F& lastUR,
                      bool sharpTurn);
   
   inline void copyIntoGfxVert(doodleline_vert_t& v, const Point2F& pos, const ColorF& color, const Point2F& uv)
   {
      GW v.x = pos.x; v.y = pos.y; v.z = 0.0f;
      
      // Convert to unsigned bytes.
      v.r = GLubyte(color.r * 255.0f);
	   v.g = GLubyte(color.g * 255.0f);
	   v.b = GLubyte(color.b * 255.0f);
	   v.a = GLubyte(color.a * 255.0f);
      
      // force opacity
      v.a = GLubyte(255.0f);
      
      v.u = uv.x; v.v = uv.y;
   }
   
public:

   utArray<Point2F>              tessPath;
   utArray<Point2F>              linePoints;
   utArray<ColorF>               lineColors;
   utArray<Point2F>              uvs;
   utArray<doodleline_vert_t>    quads;
   utArray<Point2F>              formerLastUL;
   utArray<Point2F>              formerLastUR;
   int                           vertCount;
   int                           randSeed;
   utRandomNumberGenerator       randGenerator;
   
   utArray<Splotch>              splotches;
   utArray<doodleline_vert_t>   splotchQuads;
   
   utArray<Splotch>              underSplotches;
   utArray<doodleline_vert_t>   underSplotchQuads;
   
   float                lineWidth;
   StringTableEntry     texture;
   StringTableEntry     splotchTexture;
   
   bool lineDirty;
   int lineGenerationWall;
   
   bool                 beveled;
   bool                 isSpline;
   Point2F              bevelRadius;
   CatmullRom<Point2F>  pointsSpline;
   CatmullRom<ColorF>   colorsSpline;
   
};



*/
#endif