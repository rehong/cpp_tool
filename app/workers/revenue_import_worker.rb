require 'roo'
class RevenueImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :revenue_import, retry: false

  HEADER = ["日期", "代理商", "分发渠道", "歌曲id", "ISRC", "UPC", "歌曲名", "专辑名", "艺人", "业务模式", "单价", "数量", "国家", "报表货币", "结算货币", "汇率"]

  def perform(id)
    revenue = Revenue.where(id: id).first
    revenue_file = RevenueFile.find_by(revenue_id: id)
    url = revenue_file.try(:url)
    begin
      if url && revenue
        spreadsheet = Roo::Spreadsheet.open(url)
        header = spreadsheet.row(1).map{|m| m.strip}
        if header != HEADER
          msg = '文件格式不正确'
          result = {data: nil, note: nil, err_message: msg,category: 0,created_at: Time.now}
          analysis_revenue_save(result)
          puts msg
          revenue.update(status: :error)
        else
          (2..spreadsheet.last_row).each  do |i|
            row = spreadsheet.row(i)
            income = row[10].to_f * row[11].to_f
            date = Date.strptime(row[0].to_s, "%Y%m").to_date
            hs_note = {sheet_name: spreadsheet.sheets.first,line_num: i,revenue_file_id: revenue_file.id,revenue_id: revenue.id,
              dsp_id: revenue.dsp_id,dsp_name: revenue.dsp.try(:name),start_date: revenue.start_time,end_date: revenue.end_time,income: income}
              if date < revenue.start_time or date > revenue.end_time
                result = {data: nil,note: hs_note, err_message: '歌曲结算周期不在报表结算周期内',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end
              dsp = Dsp.find_by(name: row[2])
              if dsp.nil? or dsp.id != revenue.dsp_id
                result = {data: nil,note: hs_note, err_message: '渠道方无法匹配',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end
              track = Track.find_by(title: row[6])
              if track.nil?
                result = {data: nil,note: hs_note, err_message: '歌曲无法匹配',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end
              if track.provider_id.nil?
                result = {data: nil,note: hs_note, err_message: '版权方不存在',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end

              album = Album.find_by(name: row[7])
              if album.nil?
                result = {data: nil,note: hs_note, err_message: '专辑无法匹配',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end
              artist = Artist.find_by(name: row[8])
              if artist.nil?
                result = {data: nil,note: hs_note, err_message: '艺人无法匹配',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
              end

              if track.authorize.nil?
                result = {data: nil,note: hs_note, err_message: '授权书无法匹配',category: 3,created_at: Time.now}
                analysis_revenue_save(result)
                next
               end
              business = track.authorize.authorized_businesses.first
              if business
                divided_rate = business.divided_point.to_i * 0.01
              else
                divided_rate = 1
              end
              amount_due = income * divided_rate * row[15].to_f

              @note = hs_note.merge(track_id: track.id,provider_id: track.provider_id,provider_name: track.provider.try(:name),amount_due: amount_due,divided_rate: divided_rate)
              data = {date: row[0],title: row[6],album: row[7],artist: row[8],dsp: row[2],isrc: row[4],upc: row[5],sales_type: row[9],unit_price: row[10],sales_unit: row[11], currancy: row[14],exchange_rate: row[15].to_f}
              result = {data: data,note: @note, err_message: '匹配成功',category: 1,created_at: Time.now}
              analysis_revenue_save(result,SETTINGS['analysis_success_type'])
            end
            revenue.processed!
          end
        end
      rescue => e
        puts e
        revenue.update(status: :error)
      end
      uri =  "http://dev.topdmc.com.cn:50000/publish?clientId=topdmc&publishKey=785429db07ee22ea6bbcad7dbf534ba849083bd07c06e4f7e89f18164846d5e8"
      RestClient.post(uri,{
        "event": "/dsp/data/status_changed",
        "to": "*",
        "payload":{
          "revenue_id": revenue.try(:id),
          "status": revenue.try(:status),
          "message": "系统消息",
          "description": "数据解析完成"
        }
      }.to_json)
    end


    def analysis_revenue_save(result,type=SETTINGS['analysis_error_type'])
      note = RevenueAnalysis.new(result)
      repository = AnalysisRepository.new(type: type)
      repository.save(note)
    end


  end
