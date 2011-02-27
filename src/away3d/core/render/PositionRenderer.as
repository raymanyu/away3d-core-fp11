package away3d.core.render
{
	import away3d.core.base.IRenderable;
	import away3d.core.traverse.EntityCollector;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;

	/**
	 * The PositionRenderer renders normalized position coordinates.
	 */
	public class PositionRenderer extends RendererBase
	{
		private var _program3D : Program3D;
		private var _renderBlended : Boolean;

		/**
		 * Creates a PositionRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used
		 * @param renderMode The render mode to be used.
		 */
		public function PositionRenderer(renderBlended : Boolean = false, antiAlias : uint = 0, renderMode : String = Context3DRenderMode.AUTO)
		{
			// todo: request context in here
			_renderBlended = renderBlended;
			super(antiAlias, true, renderMode);
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector) : void
		{
			var opaques : Vector.<IRenderable> = entityCollector.opaqueRenderables;
			var blendeds : Vector.<IRenderable> = entityCollector.blendedRenderables;
			var len : uint = opaques.length;
			var renderable : IRenderable;

			_context.setDepthTest(true, Context3DCompareMode.LESS);
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

			if (!_program3D) initProgram3D(_context);
			_context.setProgram(_program3D);

			for (var i : uint = 0; i < len; ++i) {
				renderable = opaques[i];
				_context.setVertexBufferAt(0, renderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
				_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);
				_context.drawTriangles(renderable.getIndexBuffer(_context, _contextIndex), 0, renderable.numTriangles);
			}

			if (!_renderBlended) return;

			len = blendeds.length;
			for (i = 0; i < len; ++i) {
				renderable = blendeds[i];
				_context.setVertexBufferAt(0, renderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
				_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);
				_context.drawTriangles(renderable.getIndexBuffer(_context, _contextIndex), 0, renderable.numTriangles);
			}
		}

		/**
		 * Creates the depth rendering Program3D.
		 * @param context The Context3D object for which the Program3D needs to be created.
		 */
		private function initProgram3D(context : Context3D) : void
		{
			var vertexCode : String;
			var fragmentCode : String;

			_program3D = context.createProgram();

			vertexCode = 	"m44 vt0, va0, vc0	\n" +
							"mov op, vt0		\n" +
							"rcp vt1.x, vt0.w	\n" +
							"mul v0, vt0, vt1.x	\n";
			fragmentCode = "mov oc, v0\n";

			_program3D.upload(	new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexCode),
								new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentCode));
		}
	}
}