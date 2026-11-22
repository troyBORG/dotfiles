#include <QApplication>
#include <QQuickWindow>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QNetworkProxy>
#include <QTimer>
#include <QTest>
#include <QFile>
#include <Plasma/Corona>
#include <Plasma/Containment>
#include <Plasma/Applet>
#include <PlasmaQuick/AppletQuickItem>
#include <KPackage/PackageLoader>
class Corona : public Plasma::Corona {
public: QRect screenGeometry(uint) const override { return QRect(0,0,1280,1024); }
};
class Driver : public QObject {
 Q_OBJECT
public:
 QQuickWindow *window;
 Q_INVOKABLE void click(QQuickItem *item) {
   QTest::mouseClick(window, Qt::LeftButton, Qt::NoModifier, item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint());
 }
 Q_INVOKABLE void stopTimers(QObject *object) {
   if(object->metaObject()->indexOfProperty("interval") >= 0 && object->metaObject()->indexOfProperty("running") >= 0) object->setProperty("running",false);
   for(auto child:object->children()) stopTimers(child);
 }
 Q_INVOKABLE void capture(QString name) { if(!window->grabWindow().save(name)) qFatal("Screenshot failed"); }
 Q_INVOKABLE void save(QString name, QString text) { QFile f(name); if(!f.open(QIODevice::WriteOnly)) qFatal("Save failed"); f.write(text.toUtf8()); }
 Q_INVOKABLE void finish(int code) { QCoreApplication::exit(code); }
};
int main(int argc,char **argv) {
 QApplication app(argc,argv);
 QPalette palette=app.palette();
 for(auto role:{QPalette::WindowText,QPalette::Text,QPalette::ButtonText}) palette.setColor(role,QColor("#eff0f1"));
 for(auto role:{QPalette::Window,QPalette::Base}) palette.setColor(role,QColor("#232629"));
 palette.setColor(QPalette::Button,QColor("#31363b")); app.setPalette(palette);
 QNetworkProxy::setApplicationProxy(QNetworkProxy(QNetworkProxy::HttpProxy,"127.0.0.1",9));
 Corona corona;
 auto shell=KPackage::PackageLoader::self()->loadPackage("Plasma/Shell"); shell.setPath("org.kde.plasma.desktop");
 if(!shell.isValid()) qFatal("Missing shell package"); corona.setKPackage(shell);
 auto containment=corona.createContainment("null");
 auto applet=containment->createApplet("com.pennywiseops.ffxitimers");
 auto item=PlasmaQuick::AppletQuickItem::itemForApplet(applet);
 if(!item || item->applet()!=applet) qFatal("Missing real AppletContext");
 QQuickWindow window; window.setColor(QColor("#232629")); window.resize(499,493);
 item->setParentItem(window.contentItem()); item->setSize(QSizeF(499,493)); item->setExpanded(true); window.show();
 Driver driver; driver.window=&window;
 QObject::connect(&window,&QQuickWindow::widthChanged,[&]{item->setWidth(window.width());});
 QObject::connect(&window,&QQuickWindow::heightChanged,[&]{item->setHeight(window.height());});
 QQmlComponent runner(qmlEngine(item),QUrl::fromLocalFile(QString::fromLocal8Bit(argv[1])));
 if(runner.isError()) { qWarning()<<runner.errors(); return 2; }
 auto test=runner.createWithInitialProperties({{"widget",QVariant::fromValue(item)}, {"driver",QVariant::fromValue(&driver)}, {"testWindow",QVariant::fromValue(&window)}, {"isBaseline",argc>2 && QString(argv[2])=="isBaseline"}});
 if(!test) {qWarning()<<runner.errors();return 2;}
 QTimer::singleShot(20000,&app,[&]{qWarning("TEST TIMEOUT");app.exit(3);});
 int code=app.exec(); delete test; return code;
}
#include "main.moc"
