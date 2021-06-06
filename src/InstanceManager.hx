package src;

import shaders.DtsTexture;
import h3d.mat.Pass;
import h3d.shader.AlphaMult;
import h2d.col.Matrix;
import src.GameObject;
import h3d.scene.Scene;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.MeshBatch;

typedef MeshBatchInfo = {
	var instances:Array<MeshInstance>;
	var meshbatch:MeshBatch;
	var ?transparencymeshbatch:MeshBatch;
	var mesh:Mesh;
}

typedef MeshInstance = {
	var emptyObj:Object;
	var gameObject:GameObject;
}

class InstanceManager {
	var objects:Map<String, Array<MeshBatchInfo>> = new Map();
	var scene:Scene;

	public function new(scene:Scene) {
		this.scene = scene;
	}

	public function update(dt:Float) {
		for (obj => meshes in objects) {
			for (minfo in meshes) {
				if (minfo.meshbatch != null) {
					var opaqueinstances = minfo.instances.filter(x -> x.gameObject.currentOpacity == 1);
					minfo.meshbatch.begin(opaqueinstances.length);
					for (instance in opaqueinstances) { // Draw the opaque shit first
						var transform = instance.emptyObj.getAbsPos().clone();
						minfo.meshbatch.setTransform(transform);
						minfo.meshbatch.emitInstance();
					}
				}
				if (minfo.transparencymeshbatch != null) {
					var transparentinstances = minfo.instances.filter(x -> x.gameObject.currentOpacity != 1);
					minfo.transparencymeshbatch.begin(transparentinstances.length);
					for (instance in transparentinstances) { // Non opaque shit
						var dtsShader = minfo.transparencymeshbatch.material.mainPass.getShader(DtsTexture);
						minfo.transparencymeshbatch.material.blendMode = Alpha;
						if (dtsShader != null) {
							dtsShader.currentOpacity = instance.gameObject.currentOpacity;
							minfo.transparencymeshbatch.shadersChanged = true;
						}
						var transform = instance.emptyObj.getAbsPos().clone();
						minfo.transparencymeshbatch.setTransform(transform);
						minfo.transparencymeshbatch.emitInstance();
					}
				}
			}
		}
	}

	public function addObject(object:GameObject) {
		function getAllChildren(object:Object):Array<Object> {
			var ret = [object];
			for (i in 0...object.numChildren) {
				ret = ret.concat(getAllChildren(object.getChildAt(i)));
			}
			return ret;
		}

		if (isInstanced(object)) {
			// Add existing instance
			var objs = getAllChildren(object);
			var minfos = objects.get(object.identifier);
			for (i in 0...objs.length) {
				minfos[i].instances.push({emptyObj: objs[i], gameObject: object});
			}
		} else {
			// First time appending the thing so bruh
			var infos = [];
			var objs = getAllChildren(object);
			var minfos = [];
			for (obj in objs) {
				var isMesh = obj is Mesh;
				var minfo:MeshBatchInfo = {
					instances: [{emptyObj: obj, gameObject: object}],
					meshbatch: isMesh ? new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene) : null,
					mesh: isMesh ? cast obj : null
				}
				if (isMesh) {
					var mat = cast(obj, Mesh).material;
					var dtsshader = mat.mainPass.getShader(DtsTexture);
					if (dtsshader != null) {
						minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
						minfo.meshbatch.material.mainPass.addShader(dtsshader);
					}
					minfo.transparencymeshbatch = new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene);
					minfo.transparencymeshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					minfo.transparencymeshbatch.material.mainPass.addShader(dtsshader);
				}
				minfos.push(minfo);
			}
			objects.set(object.identifier, minfos);
		}
	}

	public function isInstanced(object:GameObject) {
		if (objects.exists(object.identifier))
			return true;
		return false;
	}
}
