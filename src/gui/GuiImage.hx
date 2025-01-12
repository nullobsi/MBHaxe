package gui;

import shaders.GuiClipFilter;
import h2d.filter.Mask;
import gui.GuiControl.MouseState;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;
import src.MarbleGame;

@:publicFields
class GuiImage extends GuiControl {
	var bmp:Bitmap;

	public var pressedAction:GuiEvent->Void = null;

	public var doClipping:Bool = true;

	public function new(texture:Tile) {
		super();
		this.bmp = new Bitmap(texture);
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		var hittestRect = this.getHitTestRect();
		if (doClipping
			&& (hittestRect.position.x > renderRect.position.x
				|| hittestRect.position.y > renderRect.position.y
				|| hittestRect.extent.x < renderRect.extent.x
				|| hittestRect.extent.y < renderRect.extent.y)) {
			if (bmp.filter == null) {
				bmp.filter = new GuiClipFilter(hittestRect);
			}
		}
		bmp.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
		// bmp.scaleX = renderRect.extent.x / bmp.tile.width;
		// bmp.scaleY = renderRect.extent.y / bmp.tile.height;
		bmp.width = renderRect.extent.x;
		bmp.height = renderRect.extent.y;
		if (scene2d.contains(bmp)) {
			scene2d.removeChild(bmp); // Refresh "layer"
		}
		scene2d.addChild(bmp);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.bmp.remove();
	}

	public override function onMouseRelease(mouseState:MouseState) {
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null) {
			this.pressedAction(new GuiEvent(this));
		}
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(bmp)) {
			MarbleGame.canvas.scene2d.removeChild(bmp); // Refresh "layer"
		}
	}
}
