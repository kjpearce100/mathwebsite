/*
	class julia (Applet)

	Authors: 
		Julia Thrower
		July 2001

	Revisions:
		Kent Pearce
		August 2001

*/

import java.awt.*;
import java.awt.event.*;
import java.applet.*;

public class julia extends Applet {


	public Image hiddenimagebuffer;
	public Graphics hiddengraphics;

	public void init() {
		setLayout(new BorderLayout());
		ViewPanel vp = new ViewPanel(this);

		add("Center", vp);	 
		add("North", new ControlsTop(vp));
		add("South", new ControlsBot(vp));


		hiddenimagebuffer = createImage(this.size().width, this.size().height);
		hiddengraphics = hiddenimagebuffer.getGraphics();

		repaint();
	}


	public boolean handleEvent(Event e) {
		switch (e.id) {
		case Event.WINDOW_DESTROY:
			System.exit(0);
			return true;
		default:
			return false;
		}
	}


	public static void main(String args[]) {
		Frame f = new Frame("julia");
		julia view = new julia();
		view.init();
		view.start();
		f.add("Center", view);
		f.show();
	}

}


//
// *****************************************************************************
//


class ViewPanel extends Panel {

	julia parent;

	public static final int Mono = 1;
	public static final int Multi = 2;

	public static final int IterShort = 13;
	public static final int IterMedium = 27;
	public static final int IterLong =55;
	public static final int IterVeryLong = 111;

	public static final int GridUltraFine = 1;
	public static final int GridFine = 2;
	public static final int GridMedFine = 5;
	public static final int GridMedCoarse = 10;
	public static final int GridCoarse = 20;

	public static final int Quad = 1;
	public static final int Alt = 2;
	
	public static final int Julia = 1;
	public static final int Mandelbrot = 2;
	
	public static final int ZoomInPlus = -2;
	public static final int ZoomIn = -1;
	public static final int Normal = 0;
	public static final int ZoomOut = 1;
	public static final int ZoomOutPlus = 2;

	private int once = 0;

	private int bound = 2;
	
	private int shade = Multi;

	private int iteration = IterMedium;

	private int density = GridMedCoarse;

	private int fractal = Julia;
	
	private int zoom = Normal; 

	private int ftype = Quad;

	private double spq = 1.0d;

	private int gridsize = 400/density;
	private int gridlines = 2*gridsize + 1;

	private double x1, y1;
	private int x1i, y1i;

	private double cx = 0.0d;
	private double cy = 0.0d;

	private double scale = 0.011d;


	ViewPanel(julia target) {
		this.parent = target;
	}


	public void init() {
		resize(450, 425);
	}


	public void start() {
	}


	public void stop() {
	}


	public void destroy() {
	}



	public void setShade(int shade) {
		this.shade = shade;
		repaint();
	}


	public void setIteration(int iteration) {
		this.iteration = iteration;
		repaint();
	}


	public void setDensity(int density) {
		gridsize = 400/density;
		gridlines = 2*gridsize + 1;
		this.density = density;
		repaint();
	}


	public void setFractal(int fractal) {
		this.fractal = fractal;
		repaint();
	}
	
	public void setZoom(int zoom) {
		if (zoom == Normal){
			spq = 1;
			cx = 0.0d;
			cy = 0.0d;
			repaint();
		}
		this.zoom = zoom;
	}


	public void setFtype(int ftype) {
		this.ftype = ftype;
		repaint();
	}



	private int screenValue_x( double x){
		return (int) Math.round( ((x + 2.0d*spq)*size().width)/(spq*4.95d) + (0.5d - 2.0d/4.95d)*size().width);
	}


	private int screenValue_y( double y ){
		return (int) Math.round( ((spq*2.0d - y)*size().height)/(spq*4.0d));
	}
	 


	private double realValue_x( int x){
		return ( 4.95d*spq*(x - (0.5d - 2.0d/4.95d)*size().width)/size().width - 2.0d*spq);
	}


	private double realValue_y( int y ){
		return ( 2.0d*spq - 4.0d*spq*y/size().height);
	}

	 
	private int rquad (double x, double y, double x1, double y1) 
		{
		double xt, yt;
		int n = 0;
		while ( (n <= iteration) && ( x*x + y*y < bound*bound )) {
			xt = x*x - y*y;
			yt = 2.0d*x*y;
			x = xt + x1;
			y = yt + y1;
			n=n+1; 
		}
		return n;
	}	


	private int ralt (double x, double y, double x1, double y1) 
		{
		double xt, yt;
		int n = 0;
		while ( (n <= iteration) && ( x*x + y*y < bound*bound )) {

			xt = x -x*x + y*y;
			yt = y - 2.0d*x*y;
			x = xt + x1;
			y = yt + y1;   
			n=n+1; 
		}
		return n;
	}	


	public void paint(Graphics g) {
		double x, y;
		int x2[][] = new int[gridlines][gridlines];
		int y2[][] = new int[gridlines][gridlines];

		int unitlen = (int) Math.round(1.0d/scale);
		int irad = 2;

		int x0i, y0i;

		double xr, yr, xl, yl;
		int ri, rix;

		x0i = screenValue_x(0.0d); y0i = screenValue_y(0.0d);


		parent.hiddengraphics.setColor(Color.white);
		parent.hiddengraphics.fillRect(0,0,size().width,size().height);
		parent.hiddengraphics.setColor(Color.black);
		parent.hiddengraphics.drawRect(0,0,size().width-1,size().height-1);
		parent.hiddengraphics.drawArc(x0i-unitlen, y0i-unitlen, 
		unitlen*2, unitlen*2, 0, 360);
		parent.hiddengraphics.drawLine(x0i, 0, x0i, size().height-1);
		parent.hiddengraphics.drawLine(0, y0i, size().width-1, y0i);
		g.drawImage(parent.hiddenimagebuffer, 0,0, this);


		for (int i = 0; i < gridlines; i++){
			x = spq*2.0d*(i-gridsize)/gridsize;
			for (int j = 0; j < gridlines; j++){
				y = spq*2.0d*(j-gridsize)/gridsize;
				x2[i][j] = screenValue_x( x );
				y2[i][j] = screenValue_y( y );
			}
		}


		
		if (once == 1) {
 
			for (int i = 0; i < gridlines-1; i++){
		 		for (int j = 0; j < gridlines-1; j++){

					xr = realValue_x(x2[i+1][j+1]); yr = realValue_y(y2[i+1][j+1]);
					xl = realValue_x(x2[i][j]); yl = realValue_y(y2[i][j]);
		
					if (fractal == Julia) {
						if (ftype == Quad) {
							ri = rquad ((xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy,x1,y1);
						}
						else {
							ri = ralt ((xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy,x1,y1);
						};
					}
					else {
						if (ftype == Quad) {
							ri = rquad ((xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy,(xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy);
						}
						else {
							ri = ralt ((xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy,(xr+xl)/2.0d+cx,(yr+yl)/2.0d+cy);
						};
					}
		
					rix = ri - 7*((int)Math.round(ri/7));

					if (shade == Mono){
						if ( ri > iteration){
							parent.hiddengraphics.setColor(Color.black);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else {
							parent.hiddengraphics.setColor(Color.white);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
					}

					else {

						if ( ri >= iteration){
							parent.hiddengraphics.setColor(Color.black);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 6 ) {
							parent.hiddengraphics.setColor(Color.magenta);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 5) {
							parent.hiddengraphics.setColor(Color.blue);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 4) {
							parent.hiddengraphics.setColor(Color.cyan);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 3) {
							parent.hiddengraphics.setColor(Color.green);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 2) {
							parent.hiddengraphics.setColor(Color.yellow);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else if (rix == 1) {
							parent.hiddengraphics.setColor(Color.orange);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
						else  {
							parent.hiddengraphics.setColor(Color.red);
							parent.hiddengraphics.fillRect(x2[i][j+1],y2[i][j+1],x2[i+1][j]-x2[i][j],y2[i][j]-y2[i][j+1]);
						}
		 			}
				}
			}

			if ((fractal == Julia) && (zoom == Normal)) {
				parent.hiddengraphics.setColor(Color.blue);
				parent.hiddengraphics.fillArc(x1i-irad,y1i-irad,irad*2,irad*2,0,360);
			};

			g.drawImage(parent.hiddenimagebuffer, 0,0, this);
		}

		once = 1;
		
	}


	public void update(Graphics g) {
		paint(g);
	}


	public boolean mouseDown(java.awt.Event evt, int x, int y) {
		if (inside(x,y)) {
			cx = realValue_x(x)+cx;
			cy = realValue_y(y)+cy;

			if (zoom == Normal) {
				spq = 1.0d;
				cx = 0.0d;
				cy = 0.0d;
				x1i = x;
				y1i = y;
				x1 = realValue_x(x); 
				y1 = realValue_y(y);
			}
			else if (zoom == ZoomIn) {
				spq = spq/2.0d;
			}
			else if (zoom == ZoomInPlus) {
				spq = spq/10.0d;
			}
			else if (zoom == ZoomOutPlus) {
				spq = spq*10.0d;
			}
			else {
				spq = spq*2.0d;
			};

			repaint();
		}
		return true;
	}


}


//
// *****************************************************************************
//


class ControlsTop extends Panel {

	ViewPanel target;

	String st_Mono_label = "B/W";
	String st_Multi_label = "Color";

	String st_IterShort_label = "Short";
	String st_IterMedium_label = "Medium";
	String st_IterLong_label = "Long";
	String st_IterVeryLong_label = "VeryLong";

	String st_GridUltraFine_label = "UltraFine";
	String st_GridFine_label = "Fine";
	String st_GridMedFine_label = "MedFine";
	String st_GridMedCoarse_label = "MedCoarse";
	String st_GridCoarse_label = "Coarse";


	public ControlsTop (ViewPanel target) {
		this.target = target;
		setLayout(new FlowLayout(FlowLayout.CENTER));
		setBackground(Color.lightGray);

		add(new Label("Shade", Label.RIGHT));
		Choice shade = new Choice();
		shade.addItem("B/W");
		shade.addItem("Color");
		shade.addItemListener(itemshade);
		shade.select(1);
		add(shade);
		
		add(new Label("Iteration", Label.RIGHT));
		Choice iteration = new Choice();
		iteration.addItem("Short");
		iteration.addItem("Medium");
		iteration.addItem("Long");
		iteration.addItem("VeryLong");
		iteration.addItemListener(itemiteration);
		iteration.select(1);
		add(iteration);
		

		add(new Label("Density", Label.RIGHT));
		Choice density = new Choice();
		density.addItem("UltraFine");
		density.addItem("Fine");
		density.addItem("MedFine");
		density.addItem("MedCoarse");
		density.addItem("Coarse");
		density.addItemListener(itemdensity);
		density.select(2);
		add(density);

	}

ItemListener itemshade = new ItemListener () {

		public void itemStateChanged(ItemEvent itemshade) {
			if (itemshade.getItem().equals(st_Mono_label)) {
				target.setShade(ViewPanel.Mono);
			} 
			else if (itemshade.getItem().equals(st_Multi_label)) {
				target.setShade(ViewPanel.Multi);
			}
		}
	
	 };

ItemListener itemiteration = new ItemListener () {

		public void itemStateChanged(ItemEvent itemiteration) {
			if (itemiteration.getItem().equals(st_IterShort_label)) {
				target.setIteration(ViewPanel.IterShort);
			} 
			else if (itemiteration.getItem().equals(st_IterMedium_label)) {
				target.setIteration(ViewPanel.IterMedium);
			}
			else if (itemiteration.getItem().equals(st_IterLong_label)) {
				target.setIteration(ViewPanel.IterLong);
			}
			else if (itemiteration.getItem().equals(st_IterVeryLong_label)) {
				target.setIteration(ViewPanel.IterVeryLong);
			}
		}
	
	 };
	

ItemListener itemdensity = new ItemListener () {

		public void itemStateChanged(ItemEvent itemdensity) {
			if (itemdensity.getItem().equals(st_GridUltraFine_label)) {
				target.setDensity(ViewPanel.GridUltraFine);
			} 
			else if (itemdensity.getItem().equals(st_GridFine_label)) {
				target.setDensity(ViewPanel.GridFine);
			}
			else if (itemdensity.getItem().equals(st_GridMedFine_label)) {
				target.setDensity(ViewPanel.GridMedFine);
			}
			else if (itemdensity.getItem().equals(st_GridMedCoarse_label)) {
				target.setDensity(ViewPanel.GridMedCoarse);
			}
			else if (itemdensity.getItem().equals(st_GridCoarse_label)) {
				target.setDensity(ViewPanel.GridCoarse);
			}
		}
	
	 };


}


//
// *****************************************************************************
//


class ControlsBot extends Panel {

	ViewPanel target;

	String st_Quad_label = "Quad";
	String st_Alt_label = "Alt";

	String st_Julia_label = "Julia";
	String st_Mandelbrot_label = "Mandelbrot";

	String st_ZoomInPlus_label = "Zoom In Plus";
	String st_ZoomIn_label = "Zoom In";
	String st_Normal_label = "Normal";
	String st_ZoomOut_label = "Zoom Out";
	String st_ZoomOutPlus_label = "Zoom Out Plus";


	public ControlsBot (ViewPanel target) {
		this.target = target;
		setLayout(new FlowLayout(FlowLayout.CENTER));
		setBackground(Color.lightGray);

		add(new Label("Type", Label.RIGHT));
		Choice ftype = new Choice();
		ftype.addItem("Quad");
		ftype.addItem("Alt");
		ftype.addItemListener(itemftype);
		ftype.select(0);
		add(ftype);

		
		add(new Label("Fractal", Label.RIGHT));
		Choice fractal = new Choice();
		fractal.addItem("Julia");
		fractal.addItem("Mandelbrot");
		fractal.addItemListener(itemfractal);
		fractal.select(0);
		add(fractal);
		
		add(new Label("Zoom", Label.RIGHT));
		Choice zoom = new Choice();
		zoom.addItem("Zoom In Plus");
		zoom.addItem("Zoom In");
		zoom.addItem("Normal");
		zoom.addItem("Zoom Out");
		zoom.addItem("Zoom Out Plus");
		zoom.addItemListener(itemzoom);
		zoom.select(2);
		add(zoom);
	}


	ItemListener itemftype = new ItemListener () {

		public void itemStateChanged(ItemEvent itemftype) {
			if (itemftype.getItem().equals(st_Quad_label)) {
				target.setFtype(ViewPanel.Quad);
			} 
			else if (itemftype.getItem().equals(st_Alt_label)) {
				target.setFtype(ViewPanel.Alt);
			}
		}
	
	 };

	ItemListener itemfractal = new ItemListener () {

		public void itemStateChanged(ItemEvent itemfractal) {
			if (itemfractal.getItem().equals(st_Julia_label)) {
				target.setFractal(ViewPanel.Julia);
			} 
			else if (itemfractal.getItem().equals(st_Mandelbrot_label)) {
				target.setFractal(ViewPanel.Mandelbrot);
			}
		}
	
	 };

	ItemListener itemzoom = new ItemListener () {

		public void itemStateChanged(ItemEvent itemzoom) {
			if (itemzoom.getItem().equals(st_ZoomIn_label)) {
				target.setZoom(ViewPanel.ZoomIn);
			}
			else if (itemzoom.getItem().equals(st_ZoomInPlus_label)) {
				target.setZoom(ViewPanel.ZoomInPlus);
			}
			else if (itemzoom.getItem().equals(st_Normal_label)) {
				target.setZoom(ViewPanel.Normal);
			}
			else if (itemzoom.getItem().equals(st_ZoomOut_label)) {
				target.setZoom(ViewPanel.ZoomOut);
			}
			else if (itemzoom.getItem().equals(st_ZoomOutPlus_label)) {
				target.setZoom(ViewPanel.ZoomOutPlus);
			}
		}
	};

}


