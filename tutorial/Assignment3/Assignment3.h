#pragma once
#include "igl/opengl/glfw/Viewer.h"
#include <queue>
#include "./CubeData.h"
#include "./Action.h"
#include "glfw/glfw3.h"
#define CUBE_SIZE 1.0f
#define SPEED 0.05

class Assignment3 : public igl::opengl::glfw::Viewer
{
	
public:
	
	Assignment3(int wallSize);
//	Assignment3(float angle,float relationWH,float near, float far);
	void Init();
	void GenerateCubes();
	void Update(const Eigen::Matrix4f& Proj, const Eigen::Matrix4f& View, const Eigen::Matrix4f& Model, unsigned int  shaderIndx, unsigned int shapeIndx);
	void WhenRotate();
	void WhenTranslate();
	void Animate() override;
	void ScaleAllShapes(float amt, int viewportIndx);
	int GetOffset() { return offset; };
	void AddAction(int axis, int targetIndex);

	void ProjectScreenCoordToScene(double x, double y, float m_viewport[], const Eigen::Matrix4f& sceneViewInverse, Eigen::Vector3f& sceneSourceCoord, Eigen::Vector3f& sceneDir);

	bool TriangleIntersection(const Eigen::Vector3f& source, const Eigen::Vector3f& dir, const Eigen::Matrix3f& vertices, const Eigen::Vector3f& normal, Eigen::Vector3f& intersectionPoint);

	bool GetClosestIntersectingFace(CubeData* cubeData, const Eigen::Matrix4f& cubeView, const Eigen::Vector3f& sourcePointScene, const Eigen::Vector3f& dirToScene, Eigen::Vector3f& closestIntersectionToRet, int& closestFaceIndexToRet);

	void Picking(double x, double y);

	void RotateCubeByFace(CubeData* cube, int faceIndex);

	~Assignment3(void);

private:
	int wallSize, offset;
	std::vector<CubeData*> cubesData;
	std::queue<Action*> actionsQueue;
	Eigen::Matrix4f cachedProj, cachedView;
};


