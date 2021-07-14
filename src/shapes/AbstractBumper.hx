package shapes;

import collision.CollisionInfo;
import src.DtsObject;
import src.TimeState;
import src.Util;

class AbstractBumper extends DtsObject {
	var lastContactTime = Math.NEGATIVE_INFINITY;

	override function update(timeState:src.TimeState) {
		// Override the keyframe
		var currentCompletion = getCurrentCompletion(timeState);
		this.sequenceKeyframeOverride.set(this.dts.sequences[0], currentCompletion * (this.dts.sequences[0].numKeyFrames - 1));

		super.update(timeState);
	}

	function getCurrentCompletion(timeState:TimeState) {
		var elapsed = timeState.timeSinceLoad - this.lastContactTime;
		var completion = Util.clamp(elapsed / this.dts.sequences[0].duration, 0, 1);
		return completion;
	}

	override function onMarbleContact(time:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(time, contact);
		if (time.timeSinceLoad - this.lastContactTime <= 0)
			return;
		var currentCompletion = this.getCurrentCompletion(time);
		if (currentCompletion == 0 || currentCompletion == 1) {
			this.lastContactTime = time.timeSinceLoad;
		}

		// this.level.replay.recordMarbleContact(this);
	}
}
