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

void findIntersection(out float dist, out vec3 normal, out vec3 intersectionPoint, vec4 object, vec3 p0, vec3 ray) {
    dist = -1.0;
    normal = vec3(-1);
    intersectionPoint = vec3(-1);
    if(object.w <= 0) {
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
}

void findFirstIntersectingObject(out int intersectionIndex, out float intersectionDistance, out vec3 intersectionPoint, out vec3 intersectionNormal, vec3 p0, vec3 ray) {
    float minDist = -1;
    int minObjectIndex = -1;
    vec3 minInterPoint = vec3(-1);
    vec3 minInterNormal = vec3(-1);
    for(int i = 0; i < sizes[0]; i++) {
        vec4 curObject = objects[i];
        float dist;
        vec3 interNormal, interPoint;
        findIntersection(dist, interNormal, interPoint, curObject, p0, ray);
        if(dist > 1.5e-6 && (dist < minDist || minObjectIndex == -1)) {
            minDist = dist;
            minObjectIndex = i;
            minInterPoint = interPoint;
            minInterNormal = interNormal;
        }
    }
    intersectionIndex = minObjectIndex;
    intersectionDistance = minDist;
    intersectionPoint = minInterPoint;
    intersectionNormal = minInterNormal;
}

vec4 calculateColor_noTracing(vec3 vRay, vec3 point, vec3 pointNormal, int objectIndex) {
    vec4 objectColor = objColors[objectIndex];
    vec4 color = objectColor * ambient;
    int currentSpotlightIdx = 0;
    for(int i = 0; i < sizes[1]; i++) {
        vec4 curLight = lightsDirection[i];
        vec3 lightDirection = curLight.xyz;
        vec4 lightIntensity = lightsIntensity[i];

        vec3 rayToLight;
        float cosBetween;
        vec4 intensity = lightIntensity;
        if(curLight.w < 0.5) {
            //directional
            rayToLight = -lightDirection;
            // TODO: why without this it looks bad?
            intensity *= dot(normalize(rayToLight), pointNormal);
        }
        else {
            //spotlight
            vec4 spotlightInfo = lightsPosition[currentSpotlightIdx];
            vec3 spotlightPosition = spotlightInfo.xyz;
            float spotlightHalfApertureCos = spotlightInfo.w;
            rayToLight = spotlightPosition - point;
//            float cosBetween = abs(dot(normalize(-rayToLight), normalize(lightDirection)));
            float cosBetween = dot(normalize(-rayToLight), normalize(lightDirection));
            if(cosBetween <= spotlightHalfApertureCos) {
                // in range
                // TODO: do we need to?
                intensity *= cosBetween;
            }
            else {
                currentSpotlightIdx += 1;
                continue;
            }
            currentSpotlightIdx += 1;
        }

        int blockingObject;
        float blockingDist;
        vec3 blockingPoint, blockingNormal;
        findFirstIntersectingObject(blockingObject, blockingDist, blockingPoint, blockingNormal, point, rayToLight);
        if (blockingDist > 0
//            && blockingObject != objectIndex
            && (curLight.w < 0.5 || blockingDist < length(rayToLight))
//            && objects[blockingObject].w > 0
        ) {
            continue;
        }
        
        // TODO: why this max?
        vec4 diffuse = max(objectColor * intensity * dot(pointNormal, normalize(rayToLight)), vec4(vec3(0), 1));
        vec3 refl = normalize(reflect(-normalize(rayToLight), pointNormal));
        // TODO: why this max?
        vec4 specular = max(vec4(0.7) * intensity * pow(dot(-vRay, refl), objectColor.w), vec4(vec3(0), 1));
        if(objects[objectIndex].w > 0) {
            //sphere

            // TODO: why this if?
            if (dot(rayToLight, pointNormal) > 0) {
                color += specular;
            }
            color += diffuse;
        }
        else {
            // plane

            // TODO: why this min?
            color = min(color + specular, vec4(1));
            color = min(color + diffuse, vec4(1));
        }
    }
    return color;
}

void main()
{  
    vec3 vRay = normalize(position0.xyz - eye.xyz);
    int interObject;
    float interDist;
    vec3 interPoint, interNormal;
    findFirstIntersectingObject(interObject, interDist, interPoint, interNormal, eye.xyz, vRay);
//    interObject = -1;
//    float t = intersection(interObject, eye.xyz, vRay);


    vec4 color;
    if(interObject == -1) {
        color = vec4(1, 1, 1, 1);
    }
    else {
        color = calculateColor_noTracing(vRay, interPoint, interNormal, interObject);
//        color = vec4(colorCalc(interObject, interPoint, vRay, 1), 1);
//        color = vec4(1, 0, 0, 1);
    }
    gl_FragColor = color;
}
 

