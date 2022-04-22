 #version 330

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightsPosition;
uniform ivec4 sizes;

in vec3 position0;
in vec3 normal0;

layout (location = 0) out vec4 outColor;

float intersection(inout int sourceIndx,vec3 sourcePoint,vec3 v)
{
    float tmin = 1.0e10;
    int indx = -1;
    for(int i=0;i<sizes.x;i++) //every object
    {
        if(i==sourceIndx)
            continue;
        if(objects[i].w > 0) //sphere
        {
            vec3 p0o =  objects[i].xyz - sourcePoint;
            float r = objects[i].w;
            float b = dot(v,p0o);
            float delta = b*b - dot(p0o,p0o) + r*r;
             float t;
            if(delta >= 0)
            {
                if(b>=0)
                    t = b - sqrt(delta);
                else
                    t = b + sqrt(delta);
                if(t<tmin && t>0)
                {
                    tmin = t;
                    indx = i;
                }
            }
        }
        else  //plane
        {
            vec3 n =  normalize(objects[i].xyz);
            vec3 p0o = -objects[i].w*n/length(objects[i].xyz) - sourcePoint;
            float t = dot(n,p0o)/dot(n,v);
            if(t>0 && t<tmin)
            {
                tmin = t;
                indx = i;
            }
        }
    }
    sourceIndx = indx;
    return tmin;
}


//body index in objects, point on surface of object, diffuseFactor for plane squares
vec3 colorCalc(int sourceIndx, vec3 sourcePoint,vec3 u,float diffuseFactor)
{
    vec3 color = ambient.rgb*objColors[sourceIndx].rgb;
    float specularCoeff = 0.7f;
    for(int i = 0;i<sizes.y;i++) //every light source
    {
        vec3 v;
        if(lightsDirection[i].w < 0.5 ) //directional
        {
            int indx = sourceIndx;
            v = normalize(lightsDirection[i].xyz);
           //  v = normalize(vec3(0.0,0.5,-1.0));
            float t = intersection(indx,sourcePoint,-v);

            // TODO: tamir, why??? planes are see through?
            if(indx < 0 || objects[indx].w<=0) //no intersection
             {
               // vec3 u = normalize(sourcePoint - eye.xyz);
                if(objects[sourceIndx].w > 0) //sphere
                {

                    vec3 n = -normalize( sourcePoint - objects[sourceIndx].xyz);
                    vec3 refl = normalize(reflect(v,n));
                    if(dot(v,n)>0.0 )
                        color+= max(specularCoeff * lightsIntensity[i].rgb * pow(dot(refl,u),objColors[sourceIndx].a),vec3(0.0,0.0,0.0));  //specular
                    color+= max(diffuseFactor * objColors[sourceIndx].rgb * lightsIntensity[i].rgb * dot(v,n),vec3(0.0,0.0,0.0)) ;  //difuse
                    //        color = vec3(1.0,1.0,0.0);
                }
                else  //plane
                {
                    vec3 n = normalize(objects[sourceIndx].xyz);
                    vec3 refl = normalize(reflect(v,n));

                    color = min(color + max(specularCoeff * lightsIntensity[i].rgb * pow(dot(refl,u),objColors[sourceIndx].a),vec3(0.0,0.0,0.0)),vec3(1.0,1.0,1.0)); //specular
                    color = min( color + max(diffuseFactor * objColors[sourceIndx].rgb * lightsIntensity[i].rgb * dot(v,n),vec3(0.0,0.0,0.0)),vec3(1.0,1.0,1.0)); //difuse

                  //      color = vec3(1.0,1.0,0.0);
                }
            }
         //   else if(indx == 1)
          //          color = lightsIntensity[i].rgb;

        }
        else  //flashlight
        {
            int indx = -1;
            v = -normalize(lightsPosition[i].xyz - sourcePoint);
            if(dot(v,normalize(lightsDirection[i].xyz))<lightsPosition[i].w)
            {
                continue;
            }
            else
            {
                //vec3 u = normalize(sourcePoint - eye.xyz);
                float t = intersection(indx,lightsPosition[i].xyz,v);
                if(indx == sourceIndx) //no intersection
                {
                    if(objects[sourceIndx].w > 0) //sphere
                    {
                        vec3 n = -normalize( sourcePoint - objects[sourceIndx].xyz);
                        vec3 refl = normalize(reflect(v,n));
                        if(dot(v,n)>0.0)
                          color+=max(specularCoeff * lightsIntensity[i].rgb * pow(dot(refl,u),objColors[sourceIndx].a),vec3(0.0,0.0,0.0)); //specular
                        color+= max(diffuseFactor * objColors[sourceIndx].rgb * lightsIntensity[i].rgb * dot(v,n),vec3(0.0,0.0,0.0));
                      //          color = vec3(1.0,1.0,0.0);
                    }
                    else  //plane
                    {

                        vec3 n = normalize(objects[sourceIndx].xyz);
                        vec3 refl = normalize(reflect(v,n)); //specular
                        color = min(color + max(specularCoeff * lightsIntensity[i].rgb * pow(dot(refl,u),objColors[sourceIndx].a),vec3(0.0,0.0,0.0)),vec3(1.0,1.0,1.0));
                        color = min(color + max(diffuseFactor * objColors[sourceIndx].rgb * lightsIntensity[i].rgb *dot(v,n),vec3(0.0,0.0,0.0)),vec3(1.0,1.0,1.0));
                       // color = vec3(1.0,1.0,0.0);
                    }
                }
                //else if(indx == 1)
                //    color = lightsIntensity[i].rgb;
            }
        }
    }
         //   color = vec3(1.0,1.0,0.0);
    return min(color,vec3(1.0,1.0,1.0));
}

#define OBJ_KIND_PLANE 0
#define OBJ_KIND_SPHERE 1
#define isObjectOfKind(object, kind) ((object).w <= 0 == ((kind) == OBJ_KIND_PLANE))
int getObjectKind(vec4 object) {
    if (object.w <= 0) {
        return OBJ_KIND_PLANE;
    }
    else {
        return OBJ_KIND_SPHERE;
    }
}

struct Object {
    int kind;
    vec4 info;
    vec3 color;
    float shinniness;
};

Object getObject(int i) {
    vec4 object = objects[i];
    int kind = getObjectKind(object);
    vec3 color = objColors[i].xyz;
    float shinniness = objColors[i].w;
    return Object(kind, object, color, shinniness);
}

#define LIGHT_KIND_DIRECTIONAL 0
#define LIGHT_KIND_SPOTLIGHT 1
struct Light {
    int kind;
    vec3 intensity;
    vec3 direction;

    // spotlight only
    vec3 position;
    float spotlight_halfApertureCos;
};

Light getLight(int i, int positionIndex) {
    vec4 light = lightsDirection[i];
    vec4 positionInfo;
    int kind;
    if (light.w < 0.5) {
        kind = LIGHT_KIND_DIRECTIONAL;
        positionInfo = vec4(vec3(0), 1);
    }
    else {
        kind = LIGHT_KIND_SPOTLIGHT;
        positionInfo = lightsPosition[positionIndex];
    }

    vec3 direction = normalize(light.xyz);
    vec3 intensity = lightsIntensity[i].xyz;
    vec3 position = positionInfo.xyz;
    float spotlight_halfApertureCos = positionInfo.w;
    return Light(kind, intensity, direction, position, spotlight_halfApertureCos);
}

struct Intersection {
    int objectIndex;
    float distance;
    vec3 point;
    vec3 pointNormal;
};

Intersection findIntersection(vec4 object, vec3 p0, vec3 ray) {
    float dist = -1.0;
    vec3 normal = vec3(-1);
    vec3 intersectionPoint = vec3(-1);
    if(isObjectOfKind(object, OBJ_KIND_PLANE)) {
        //plane

        float d = object.w;
        normal = normalize(object.xyz);
        dist = -(dot(normal, p0) + d) / dot(normal, ray);
        intersectionPoint = p0 + ray*dist;
    }
    else {
        //sphere
        vec3 o = object.xyz;
        float r = object.w;
        vec3 L = o - p0;
        float tm = dot(L, ray);
        float dSquared = pow(length(L), 2) - pow(tm, 2);
        if(dSquared <= pow(r, 2)) {
            float th = sqrt(pow(r, 2) - dSquared);
            float t1 = tm - th, t2 = tm + th;
            if(t1 > 0) {
                if(t2 > 0) {
                    dist = min(t1, t2);
                }
                else {
                    dist = t1;
                }
            }
            else {
                dist = t2;
            }
            intersectionPoint = p0 + ray*dist;
            normal = normalize(intersectionPoint - o);
        }
    }
    return Intersection(-1, dist, intersectionPoint, normal);
}

Intersection findFirstIntersectingObject(vec3 p0, vec3 ray) {
    Intersection minIntersection = Intersection(-1, -1, vec3(-1), vec3(-1));
    for(int i = 0; i < sizes[0]; i++) {
        vec4 curObject = objects[i];
        Intersection intersection = findIntersection(curObject, p0, ray);
        if(intersection.distance > 1.5e-6 && (minIntersection.objectIndex == -1 || intersection.distance < minIntersection.distance)) {
            intersection.objectIndex = i;
            minIntersection = intersection;
        }
    }
    return minIntersection;
}

float squareMod(float c, float factor, float sideLength) {
    return mod(int((factor * c) / sideLength), 2);
}

struct PlaneEquation {
    vec3 anchor;
    vec3 base1;
    vec3 base2;
};

PlaneEquation findBaseForPlane(vec4 plane) {
    float d = plane.w;
    vec3 planeCoefficients = plane.xyz;
    vec3 planeNormal = normalize(planeCoefficients);
    vec3 anchor = (d / dot(planeCoefficients, planeCoefficients)) * planeCoefficients;
    vec3 b1, b2;
    if (plane.x == 0 && plane.y == 0) {
        b1 = vec3(1, 0, 0);
        b2 = vec3(0, 1, 0);
    }
    else {
        b1 = normalize(vec3(-plane.y, plane.x, 0));
        b2 = normalize(cross(b1, planeNormal));
    }
    return PlaneEquation(anchor, b1, b2);
}

vec2 calculateBaseCoordinates(PlaneEquation planeBase, vec3 point) {
    // `mat2x3` is actually a 3x2 matrix.
    // Solve the following linear equation system:
    //   anchor + mat2x3(base1, base2) * vec2(x, y) = point
    // Equivalently, solve:
    //   mat2x3(base1, base2) * vec2(x, y) = point - anchor
    // The solution vec2(x, y)
    mat2x3 coefficients = mat2x3(planeBase.base1, planeBase.base2);
    mat3x2 coefficientsT = transpose(coefficients);
    mat3x2 leftInverse = inverse(coefficientsT * coefficients) * coefficientsT;
    return leftInverse * (point - planeBase.anchor);
}

#define PLANE_SQUARE_SIDE_LENGTH (1 / 1.5)
int calcSquareIndex(float x) {
    return int(mod(int(x / PLANE_SQUARE_SIDE_LENGTH), 2));
}

bool isDarkSquare(vec2 point) {
    bool equalSqaureIndex = calcSquareIndex(point.x) == calcSquareIndex(point.y);
    bool equalSign = (point.x < 0) == (point.y < 0);
    return equalSqaureIndex == equalSign;
}

float calculateDiffuseFactor(vec4 object, vec3 point) {
    float diffuseFactor =1;
    if (isObjectOfKind(object, OBJ_KIND_PLANE)) {
        PlaneEquation planeEquation = findBaseForPlane(object);
        vec2 mappedCoordinates = calculateBaseCoordinates(planeEquation, point);
        if (isDarkSquare(mappedCoordinates)) {
            diffuseFactor = 0.5;
        }
    }

    return diffuseFactor;
}

bool isShadowing(Intersection hit, Intersection blocking, Light light) {
    bool isValid = blocking.objectIndex >= 0;
    bool isSameObject = blocking.objectIndex == hit.objectIndex;
    bool isBlockingASphere = isObjectOfKind(objects[blocking.objectIndex], OBJ_KIND_SPHERE);

    // A plane cannot block itself and a sphere can
    bool sameObjectIffIsPlane = isSameObject != isBlockingASphere;

    // (light is Spotlight) -> o1 != o2
    // bool spotlightImpliesDifferentObject = light.kind == LIGHT_KIND_DIRECTIONAL || !isSameObject;

    // (light is Directional) -> ((o1 == o2) <--> (object is Sphere))
    // bool directionalLightImpliesSameObjectIffObjectIsPlane = light.kind == LIGHT_KIND_SPOTLIGHT || (isSameObject != isSphere);

    // Only block when either if the light is directional or if the 'blocking' object appears between the point and the spotlight
     vec3 vPointToLightUnnormalized = light.position - hit.point;
     bool spotlightImpliesBlockingIsBetween = light.kind == LIGHT_KIND_DIRECTIONAL || blocking.distance < length(vPointToLightUnnormalized);
     
    return isValid && sameObjectIffIsPlane && spotlightImpliesBlockingIsBetween;
}

vec3 calculateColor_noTracing(vec3 vRay, Intersection intersection) {
    Object object = getObject(intersection.objectIndex);

    vec3 specularFactors = vec3(0.7);
    vec3 diffuseFactors = vec3(calculateDiffuseFactor(object.info, intersection.point));

    object.color = diffuseFactors * object.color;
    vec3 color = object.color * ambient.xyz;

    int spotlightIndex = 0;
    for(int i = 0; i < sizes[1]; i++) {
        Light light = getLight(i, spotlightIndex);

        vec3 intensity = light.intensity;
//        intensity *= dot(vPointToLight, pointNormal);

        vec3 vPointToLight;
        if(light.kind == LIGHT_KIND_DIRECTIONAL) {
            //directional
            vPointToLight = -light.direction;
            // TODO: why without this it looks bad?
             intensity *= dot(vPointToLight, intersection.pointNormal);
        }
        else {
            //spotlight
            spotlightIndex += 1;
            vPointToLight = normalize(light.position - intersection.point);
            float cosBetween = dot(-vPointToLight, light.direction);
            if(cosBetween <= light.spotlight_halfApertureCos) {
                // in range
                // TODO: do we need to?
                intensity *= cosBetween;
            }
            else {
                continue;
            }
        }

        Intersection blockingIntersection = findFirstIntersectingObject(intersection.point, vPointToLight);
        if (isShadowing(intersection, blockingIntersection, light)) {
            continue;
        }

        // TODO: why this max?
        vec3 diffuse = object.color * intensity * dot(intersection.pointNormal, vPointToLight);
        diffuse = max(diffuse, vec3(0));
        vec3 refl = normalize(reflect(-vPointToLight, intersection.pointNormal));
        vec3 specular = specularFactors * intensity * pow(dot(-vRay, refl), object.shinniness);
        // TODO: why this max?
        specular = max(specular, vec3(0));
        if(object.kind == OBJ_KIND_SPHERE) {
            //sphere

            // TODO: why this if?
            //       and why is the `vPointToLight` should not be negated?
            if (dot(vPointToLight, intersection.pointNormal) > 0) {
                color += specular;
            }
            color += diffuse;
        }
        else {
            // plane

            // TODO: why this min?
            color = min(color + specular, vec3(1));
            color = min(color + diffuse, vec3(1));
        }
    }

    return color;
}

void main()
{
    vec3 vRay = normalize(position0.xyz - eye.xyz);
    Intersection intersection = findFirstIntersectingObject(position0, vRay);
//    interObject = -1;
//    float t = intersection(interObject, position0, vRay);
//    interPoint = position0 + t*vRay;


    vec3 color;
    if(intersection.objectIndex < 0) {
        color = vec3(1, 1, 1);
    }
    else {
        color = calculateColor_noTracing(vRay, intersection);
//        float diffuseFactor = calculateDiffuseFactor(objects[intersection.objectIndex], intersection.point);
//        color = colorCalc(intersection.objectIndex, intersection.point, vRay, diffuseFactor);
//        color = vec4(1, 0, 0, 1);
    }
    outColor = vec4(color, 1);
}
